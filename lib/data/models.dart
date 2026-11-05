import 'package:flutter/material.dart';

import '../core/constants.dart';

enum AppGoal {
  everydayEnglish,
  studyCampus,
  jobInterviews,
  workBusiness,
  travelAbroad,
  ieltsSpeaking,
}

extension AppGoalX on AppGoal {
  String get label => switch (this) {
        AppGoal.everydayEnglish => 'Everyday English',
        AppGoal.studyCampus => 'Study & campus',
        AppGoal.jobInterviews => 'Job interviews',
        AppGoal.workBusiness => 'Work & business',
        AppGoal.travelAbroad => 'Travel & abroad',
        AppGoal.ieltsSpeaking => 'IELTS speaking',
      };

  String get bnLabel => switch (this) {
        AppGoal.everydayEnglish => 'দৈনন্দিন ইংরেজি',
        AppGoal.studyCampus => 'পড়াশোনা ও ক্যাম্পাস',
        AppGoal.jobInterviews => 'চাকরির ইন্টারভিউ',
        AppGoal.workBusiness => 'কাজ ও ব্যবসা',
        AppGoal.travelAbroad => 'ভ্রমণ ও বিদেশ',
        AppGoal.ieltsSpeaking => 'আইইএলটিএস স্পিকিং',
      };

  String get hiLabel => switch (this) {
        AppGoal.everydayEnglish => 'रोज़मर्रा की अंग्रेज़ी',
        AppGoal.studyCampus => 'पढ़ाई और कैंपस',
        AppGoal.jobInterviews => 'जॉब इंटरव्यू',
        AppGoal.workBusiness => 'काम और बिज़नेस',
        AppGoal.travelAbroad => 'यात्रा और विदेश',
        AppGoal.ieltsSpeaking => 'आईईएलटीएस स्पीकिंग',
      };

  String get blurb => switch (this) {
        AppGoal.everydayEnglish => 'Small talk, daily life, and speaking without fear.',
        AppGoal.studyCampus => 'Classes, presentations, and conversations with classmates.',
        AppGoal.jobInterviews => 'Present your strengths and answer with confidence.',
        AppGoal.workBusiness => 'Meetings, client calls, and professional English.',
        AppGoal.travelAbroad => 'Airports, hotels, restaurants, and new countries.',
        AppGoal.ieltsSpeaking => 'Part 1, 2 (cue card), and 3 practice with band feedback.',
      };

  String get bnBlurb => switch (this) {
        AppGoal.everydayEnglish => 'প্রতিদিনের সাধারণ কথোপকথন ও জড়তা কাটানো।',
        AppGoal.studyCampus => 'ক্লাস, প্রেজেন্টেশন ও সহপাঠীর সাথে কথা বলা।',
        AppGoal.jobInterviews => 'চাকরির ইন্টারভিউয়ে নিজের শক্তি তুলে ধরা।',
        AppGoal.workBusiness => 'অফিস মিটিং, ক্লায়েন্ট কল ও প্রফেশনাল ইংরেজি।',
        AppGoal.travelAbroad => 'এয়ারপোর্ট, হোটেল, রেস্তোরাঁ ও বিদেশ ভ্রমণ।',
        AppGoal.ieltsSpeaking => 'পার্ট ১, ২ (কিউ কার্ড) ও পার্ট ৩ প্রস্তুতি।',
      };

  IconData get icon => switch (this) {
        AppGoal.everydayEnglish => Icons.wb_sunny_outlined,
        AppGoal.studyCampus => Icons.school_outlined,
        AppGoal.jobInterviews => Icons.work_outline_rounded,
        AppGoal.workBusiness => Icons.business_center_outlined,
        AppGoal.travelAbroad => Icons.flight_takeoff_rounded,
        AppGoal.ieltsSpeaking => Icons.workspace_premium_outlined,
      };

  String get category => switch (this) {
        AppGoal.everydayEnglish => 'Everyday English',
        AppGoal.studyCampus => 'Study & campus',
        AppGoal.jobInterviews => 'Job interviews',
        AppGoal.workBusiness => 'Work & business',
        AppGoal.travelAbroad => 'Travel & abroad',
        AppGoal.ieltsSpeaking => 'IELTS speaking',
      };
}

enum CefrLevel { beginner, intermediate, advanced }

extension CefrLevelX on CefrLevel {
  String get label => switch (this) {
        CefrLevel.beginner => 'Beginner',
        CefrLevel.intermediate => 'Intermediate',
        CefrLevel.advanced => 'Advanced',
      };

  String get band => switch (this) {
        CefrLevel.beginner => 'A1 – A2',
        CefrLevel.intermediate => 'B1 – B2',
        CefrLevel.advanced => 'C1 – C2',
      };

  String get description => switch (this) {
        CefrLevel.beginner => 'I can use simple words and short sentences.',
        CefrLevel.intermediate => 'I can keep a conversation going with some help.',
        CefrLevel.advanced => 'I can speak fluently about complex ideas.',
      };

  String get bnDescription => switch (this) {
        CefrLevel.beginner => 'সহজ শব্দ ও ছোট বাক্য ব্যবহার করতে পারি।',
        CefrLevel.intermediate => 'সাহায্য নিয়ে হলেও কথোপকথন চালিয়ে যেতে পারি।',
        CefrLevel.advanced => 'জটিল বিষয়েও সাবলীলভাবে কথা বলতে পারি।',
      };

  IconData get icon => switch (this) {
        CefrLevel.beginner => Icons.eco_outlined,
        CefrLevel.intermediate => Icons.auto_graph_rounded,
        CefrLevel.advanced => Icons.rocket_launch_outlined,
      };
}

enum HelpLanguage { english, bangla, hindi }

extension HelpLanguageX on HelpLanguage {
  String get label => switch (this) {
        HelpLanguage.english => 'English',
        HelpLanguage.bangla => 'বাংলা (Bangla)',
        HelpLanguage.hindi => 'हिन्दी (Hindi)',
      };
}

class Persona {
  const Persona({
    required this.id,
    required this.name,
    required this.role,
    required this.accent,
    required this.tagline,
    required this.greeting,
    required this.emoji,
    required this.colors,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String role;
  final String accent;
  final String tagline;
  final String greeting;
  final String emoji;
  final List<Color> colors;
  final bool isCustom;

  Persona copyWith({String? name, String? role, bool? isCustom}) => Persona(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        accent: accent,
        tagline: tagline,
        greeting: greeting,
        emoji: emoji,
        colors: colors,
        isCustom: isCustom ?? this.isCustom,
      );
}

class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    required this.aiRole,
    required this.openingLine,
    required this.emoji,
    required this.level,
    required this.goals,
    required this.colors,
    required this.personaId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final String aiRole;
  final String openingLine;
  final String emoji;
  final CefrLevel level;
  final List<String> goals;
  final List<Color> colors;
  final String personaId;

  Scenario copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? category,
    String? description,
    String? aiRole,
    String? openingLine,
    String? emoji,
    CefrLevel? level,
    List<String>? goals,
    List<Color>? colors,
    String? personaId,
  }) =>
      Scenario(
        id: id ?? this.id,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        category: category ?? this.category,
        description: description ?? this.description,
        aiRole: aiRole ?? this.aiRole,
        openingLine: openingLine ?? this.openingLine,
        emoji: emoji ?? this.emoji,
        level: level ?? this.level,
        goals: goals ?? this.goals,
        colors: colors ?? this.colors,
        personaId: personaId ?? this.personaId,
      );
}

enum VocabTone { casual, formal, idiomatic }

extension VocabToneX on VocabTone {
  String get label => switch (this) {
        VocabTone.casual => 'Casual',
        VocabTone.formal => 'Business Formal',
        VocabTone.idiomatic => 'Native Idiomatic',
      };

  String get shortLabel => switch (this) {
        VocabTone.casual => 'Everyday',
        VocabTone.formal => 'Formal',
        VocabTone.idiomatic => 'Idiomatic',
      };

  IconData get icon => switch (this) {
        VocabTone.casual => Icons.chat_bubble_outline_rounded,
        VocabTone.formal => Icons.badge_outlined,
        VocabTone.idiomatic => Icons.auto_awesome_outlined,
      };
}

class VocabWord {
  const VocabWord({
    required this.word,
    required this.phonetic,
    required this.meaningBn,
    required this.meaningEn,
    required this.example,
    required this.tone,
    this.tip = '',
  });

  final String word;
  final String phonetic;
  final String meaningBn;
  final String meaningEn;
  final String example;
  final VocabTone tone;
  final String tip;

  String get id => '${tone.name}:$word';
}

class Phrase {
  const Phrase({
    required this.text,
    required this.ipa,
    required this.banglaTip,
    required this.focus,
  });

  final String text;
  final String ipa;
  final String banglaTip;
  final String focus;
}

class AiReply {
  const AiReply({
    required this.reply,
    this.emotion = 'encouraging',
    this.betterWay = '',
    this.casualTone = '',
    this.formalTone = '',
    this.idiomaticTone = '',
    this.banglaTip = '',
    this.vocabWord = '',
    this.hintForUser = '',
    this.correction = '',
  });

  final String reply;
  final String emotion;
  final String betterWay;
  final String casualTone;
  final String formalTone;
  final String idiomaticTone;
  final String banglaTip;
  final String vocabWord;
  final String hintForUser;
  final String correction;

  factory AiReply.fromJson(Map<String, dynamic> json) {
    String read(String key, [String fallback = '']) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    return AiReply(
      reply: read('reply', 'That sounds interesting. Tell me more!'),
      emotion: read('emotion', 'encouraging'),
      betterWay: read('betterWay'),
      casualTone: read('casualTone'),
      formalTone: read('formalTone'),
      idiomaticTone: read('idiomaticTone'),
      banglaTip: read('banglaTip'),
      vocabWord: read('vocabWord'),
      hintForUser: read('hintForUser'),
      correction: read('correction'),
    );
  }

  Map<String, dynamic> toJson() => {
        'reply': reply,
        'emotion': emotion,
        'betterWay': betterWay,
        'casualTone': casualTone,
        'formalTone': formalTone,
        'idiomaticTone': idiomaticTone,
        'banglaTip': banglaTip,
        'vocabWord': vocabWord,
        'hintForUser': hintForUser,
        'correction': correction,
      };
}

enum ChatRole { ai, user }

class ChatTurn {
  ChatTurn({
    required this.role,
    required this.text,
    this.reply,
    DateTime? time,
    this.isBangla = false,
  }) : time = time ?? DateTime.now();

  final ChatRole role;
  final String text;
  final AiReply? reply;
  final DateTime time;
  final bool isBangla;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'text': text,
        'time': time.toIso8601String(),
        'isBangla': isBangla,
        if (reply != null) 'reply': reply!.toJson(),
      };

  factory ChatTurn.fromJson(Map<String, dynamic> json) => ChatTurn(
        role: json['role'] == 'user' ? ChatRole.user : ChatRole.ai,
        text: json['text'] as String? ?? '',
        isBangla: json['isBangla'] as bool? ?? false,
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        reply: json['reply'] is Map<String, dynamic>
            ? AiReply.fromJson(json['reply'] as Map<String, dynamic>)
            : null,
      );
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.date,
    required this.scenarioTitle,
    required this.personaName,
    required this.durationSeconds,
    required this.turns,
    required this.words,
    required this.fillers,
    required this.fluency,
    this.newWords = const [],
  });

  final String id;
  final DateTime date;
  final String scenarioTitle;
  final String personaName;
  final int durationSeconds;
  final int turns;
  final int words;
  final int fillers;
  final int fluency;
  final List<String> newWords;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'scenarioTitle': scenarioTitle,
        'personaName': personaName,
        'durationSeconds': durationSeconds,
        'turns': turns,
        'words': words,
        'fillers': fillers,
        'fluency': fluency,
        'newWords': newWords,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        scenarioTitle: json['scenarioTitle'] as String? ?? 'Free talk',
        personaName: json['personaName'] as String? ?? 'Sarah',
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        turns: json['turns'] as int? ?? 0,
        words: json['words'] as int? ?? 0,
        fillers: json['fillers'] as int? ?? 0,
        fluency: json['fluency'] as int? ?? 0,
        newWords: (json['newWords'] as List?)?.cast<String>() ?? const [],
      );
}

enum WordStatus { perfect, close, missed }

class WordScore {
  const WordScore({
    required this.word,
    required this.status,
    this.spokenAs = '',
  });

  final String word;
  final WordStatus status;
  final String spokenAs;

  double get value => switch (status) {
        WordStatus.perfect => 1,
        WordStatus.close => 0.55,
        WordStatus.missed => 0,
      };
}

class PronunciationResult {
  const PronunciationResult({
    required this.phrase,
    required this.transcript,
    required this.words,
    required this.score,
  });

  final String phrase;
  final String transcript;
  final List<WordScore> words;
  final int score;

  int get perfectCount =>
      words.where((w) => w.status == WordStatus.perfect).length;
  int get closeCount => words.where((w) => w.status == WordStatus.close).length;
  int get missedCount =>
      words.where((w) => w.status == WordStatus.missed).length;
}

class BandResult {
  const BandResult({
    required this.overall,
    required this.criteria,
    required this.feedback,
    required this.words,
    required this.wpm,
    required this.fillers,
  });

  final double overall;
  final Map<String, double> criteria;
  final Map<String, String> feedback;
  final int words;
  final int wpm;
  final int fillers;
}

class CallReport {
  const CallReport({
    required this.scenario,
    required this.persona,
    required this.durationSeconds,
    required this.turns,
    required this.words,
    required this.fillers,
    required this.fluency,
    required this.betterWay,
    required this.casualTone,
    required this.formalTone,
    required this.idiomaticTone,
    required this.banglaTip,
    required this.vocab,
    required this.strengths,
    required this.improvements,
  });

  final Scenario scenario;
  final Persona persona;
  final int durationSeconds;
  final int turns;
  final int words;
  final int fillers;
  final int fluency;
  final String betterWay;
  final String casualTone;
  final String formalTone;
  final String idiomaticTone;
  final String banglaTip;
  final List<String> vocab;
  final List<String> strengths;
  final List<String> improvements;
}

class OtaConfig {
  const OtaConfig({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.apkUrl,
    required this.changelog,
    this.forceUpdate = false,
    this.notice = '',
  });

  final int latestVersionCode;
  final String latestVersionName;
  final String apkUrl;
  final String changelog;
  final bool forceUpdate;
  final String notice;

  bool get hasUpdate => latestVersionCode > AppInfoVersion.code;

  factory OtaConfig.fromJson(Map<String, dynamic> json) => OtaConfig(
        latestVersionCode:
            (json['latestVersionCode'] as num?)?.toInt() ?? AppInfoVersion.code,
        latestVersionName:
            json['latestVersionName'] as String? ?? AppInfoVersion.name,
        apkUrl: json['apkUrl'] as String? ?? '',
        changelog: json['changelog'] as String? ?? '',
        forceUpdate: json['forceUpdate'] as bool? ?? false,
        notice: json['notice'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'latestVersionCode': latestVersionCode,
        'latestVersionName': latestVersionName,
        'apkUrl': apkUrl,
        'changelog': changelog,
        'forceUpdate': forceUpdate,
        'notice': notice,
      };
}

/// Kept separate to avoid a circular import with constants.dart.
class AppInfoVersion {
  static const code = AppInfo.versionCode;
  static const name = AppInfo.versionName;
}

class VoiceProfile {
  const VoiceProfile({
    this.displayName = 'Familiar Person',
    this.photoBase64 = '',
    this.voiceFileName = '',
    this.cloned = false,
  });

  final String displayName;
  final String photoBase64;
  final String voiceFileName;
  final bool cloned;

  VoiceProfile copyWith({
    String? displayName,
    String? photoBase64,
    String? voiceFileName,
    bool? cloned,
  }) =>
      VoiceProfile(
        displayName: displayName ?? this.displayName,
        photoBase64: photoBase64 ?? this.photoBase64,
        voiceFileName: voiceFileName ?? this.voiceFileName,
        cloned: cloned ?? this.cloned,
      );

  bool get hasPhoto => photoBase64.isNotEmpty;
  bool get hasVoice => voiceFileName.isNotEmpty;
}
