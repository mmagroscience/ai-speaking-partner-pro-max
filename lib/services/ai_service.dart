import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../data/demo_ai.dart';
import '../data/models.dart';

/// Talks to the Gemini REST API with multi-key rotation and a local fallback.
///
/// The user's API keys never leave the device except in the request to Google.
/// For a production build, proxy these calls through your own backend.
class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  List<String> _keys = const [];
  int _cursor = 0;

  String lastSource = 'Offline coach';
  String? lastError;

  void setKeys(List<String> keys) {
    _keys = keys
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList(growable: false);
    _cursor = 0;
  }

  bool get hasKeys => _keys.isNotEmpty;

  Future<AiReply> reply({
    required Persona persona,
    required Scenario scenario,
    required List<ChatTurn> history,
    required String userText,
    required CefrLevel level,
    required bool banglaMode,
  }) async {
    if (_keys.isEmpty) {
      lastSource = 'Offline coach';
      return DemoAi.reply(
        persona: persona,
        scenario: scenario,
        history: history,
        userText: userText,
        level: level,
        banglaMode: banglaMode,
      );
    }

    final start = _cursor;
    for (var attempt = 0; attempt < _keys.length; attempt++) {
      final index = (start + attempt) % _keys.length;
      try {
        final result = await _callGemini(
          key: _keys[index],
          persona: persona,
          scenario: scenario,
          history: history,
          userText: userText,
          level: level,
          banglaMode: banglaMode,
        );
        _cursor = (index + 1) % _keys.length;
        lastSource = 'Gemini';
        lastError = null;
        return result;
      } catch (e) {
        lastError = e.toString();
        if (kDebugMode) {
          debugPrint('Gemini key ${index + 1} failed: $e');
        }
      }
    }

    lastSource = 'Offline coach';
    return DemoAi.reply(
      persona: persona,
      scenario: scenario,
      history: history,
      userText: userText,
      level: level,
      banglaMode: banglaMode,
    );
  }

  Future<AiReply> _callGemini({
    required String key,
    required Persona persona,
    required Scenario scenario,
    required List<ChatTurn> history,
    required String userText,
    required CefrLevel level,
    required bool banglaMode,
  }) async {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$kGeminiModel:generateContent',
      {'key': key},
    );

    final transcript = StringBuffer();
    for (final turn in history.length > 12
        ? history.sublist(history.length - 12)
        : history) {
      final speaker = turn.role == ChatRole.user ? 'Learner' : persona.name;
      transcript.writeln('$speaker: ${turn.text}');
    }
    transcript.writeln('Learner: $userText');

    final system = '''
You are ${persona.name}, a ${persona.role} with a ${persona.accent}.
You are role-playing this scenario: ${scenario.title} — ${scenario.description}.
Your role in the scene: ${scenario.aiRole}.
The learner is at CEFR level ${level.label} (${level.band}).
${banglaMode ? 'The learner may speak Bangla. Understand it, then reply in simple English and include a short Bangla explanation.' : ''}

Rules:
- Stay in character. Be warm, natural, and concise (2-4 sentences).
- Always end with one clear follow-up question that keeps the learner speaking.
- Gently correct at most one important mistake. Do not correct every small thing.
- Never shame the learner. Praise something specific when possible.
- Return ONLY valid JSON with these exact keys:
  reply, emotion, betterWay, casualTone, formalTone, idiomaticTone, banglaTip, vocabWord, hintForUser, correction.
- emotion must be one of: happy, encouraging, curious, proud, caring, focused, attentive.
- betterWay: a more natural version of the learner's last sentence (empty if it was already good).
- casualTone, formalTone, idiomaticTone: rewrite the learner's last sentence in each style.
- banglaTip: one short, helpful grammar/pronunciation tip in Bangla.
- hintForUser: a tiny nudge for what to say next.
''';

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': system}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Conversation so far:\n${transcript.toString()}\nRespond to the learner\'s last message now. Return JSON only.'
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.85,
        'maxOutputTokens': 800,
        'responseMimeType': 'application/json',
      },
    });

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw AiException('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AiException('Unexpected response shape');
    }
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final feedback = decoded['promptFeedback'];
      throw AiException('No candidates returned: $feedback');
    }
    final content = (candidates.first as Map)['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw const AiException('No content parts returned');
    }
    final text = parts
        .whereType<Map>()
        .map((p) => p['text'])
        .whereType<String>()
        .join()
        .trim();
    if (text.isEmpty) throw const AiException('Empty model response');

    final map = _extractJson(text);
    final reply = AiReply.fromJson(map);
    if (reply.reply.trim().isEmpty) {
      throw const AiException('Model returned an empty reply');
    }
    return reply;
  }

  Map<String, dynamic> _extractJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final first = cleaned.indexOf('{');
    final last = cleaned.lastIndexOf('}');
    if (first >= 0 && last > first) {
      cleaned = cleaned.substring(first, last + 1);
    }
    final value = jsonDecode(cleaned);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const AiException('Model response was not a JSON object');
  }

  void dispose() {
    _client.close();
  }
}

class AiException implements Exception {
  const AiException(this.message);
  final String message;

  @override
  String toString() => 'AiException: $message';
}
