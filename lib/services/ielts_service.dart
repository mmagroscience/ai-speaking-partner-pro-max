import 'dart:math' as math;

import '../core/constants.dart';
import '../data/models.dart';

class IeltsService {
  IeltsService._();

  static BandResult estimate({
    required List<String> answers,
    required int seconds,
    required int fillers,
    double? pronunciation,
  }) {
    final text = answers.join(' ').trim();
    final words = AppUtils.wordCount(text);
    final safeSeconds = math.max(seconds, 1);
    final wpm = (words / safeSeconds * 60).round().clamp(0, 300);

    final tokens = RegExp(r"[a-zA-Z']+")
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
    final uniqueRatio = tokens.isEmpty
        ? 0.0
        : tokens.toSet().length / tokens.length;
    final longWordRatio = tokens.isEmpty
        ? 0.0
        : tokens.where((w) => w.length >= 7).length / tokens.length;
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final avgSentence = sentences.isEmpty
        ? 0.0
        : tokens.length / sentences.length;

    var grammarErrors = 0;
    const patterns = [
      r"\bi am agree\b",
      r"\bmore better\b",
      r"\bdidn't went\b",
      r"\b(he|she) don't\b",
      r"\bdiscuss about\b",
      r"\breturn back\b",
      r"\bexplain me\b",
    ];
    final lower = text.toLowerCase();
    for (final pattern in patterns) {
      if (RegExp(pattern).hasMatch(lower)) grammarErrors++;
    }

    var fluency = 4.8 +
        math.min(wpm / 55.0, 2.2) +
        math.min(words / 90.0, 1.0) -
        math.min(fillers * 0.14, 1.1);
    if (answers.length >= 3 && words > 120) fluency += 0.2;

    var lexical = 4.6 + (uniqueRatio * 2.6) + (longWordRatio * 2.2);
    if (tokens.length > 100) lexical += 0.2;

    var grammar = 5.0 +
        math.min(avgSentence / 11.0, 1.4) +
        math.min(answers.length * 0.08, 0.4) -
        grammarErrors * 0.35;

    final pron = pronunciation ??
        (5.8 +
            math.min(wpm / 100.0, 0.8) +
            math.min(uniqueRatio, 0.5));

    double clampBand(double value) =>
        (value.clamp(4.0, 8.5) * 2).round() / 2;

    final criteria = {
      'Fluency & coherence': clampBand(fluency),
      'Lexical resource': clampBand(lexical),
      'Grammatical range': clampBand(grammar),
      'Pronunciation': clampBand(pron),
    };

    final overall = clampBand(
      criteria.values.fold<double>(0, (sum, v) => sum + v) / criteria.length,
    );

    final feedback = {
      'Fluency & coherence': _fluencyFeedback(wpm, fillers, words, answers.length),
      'Lexical resource': uniqueRatio > 0.6
          ? 'Nice variety of words. Add one precise topic word to sound more advanced.'
          : 'You repeated several words. Learn 2–3 synonyms for the topic and use them next time.',
      'Grammatical range': grammarErrors > 0
          ? 'A few accuracy slips appeared. Slow down on past tense and subject–verb agreement.'
          : 'Your grammar was accurate. Now try one complex sentence with “although” or “which”.',
      'Pronunciation': pron >= 7
          ? 'Clear and easy to follow. Keep working on sentence stress rather than individual sounds.'
          : 'Focus on word endings and clear consonants. Re-record a short answer and compare.',
    };

    return BandResult(
      overall: overall,
      criteria: criteria,
      feedback: feedback,
      words: words,
      wpm: wpm,
      fillers: fillers,
    );
  }

  static String _fluencyFeedback(
      int wpm, int fillers, int words, int answers) {
    if (words < 40) {
      return 'Your answer was quite short. Aim for at least 2–3 sentences with a reason and an example.';
    }
    if (fillers >= 5) {
      return 'You used several fillers. Replace “um” with a short pause — silence sounds more confident than a filler.';
    }
    if (wpm < 90) {
      return 'Your pace was slow but clear. Try joining two ideas with “because” or “so that”.';
    }
    if (wpm > 190) {
      return 'You spoke very fast. Add small pauses between ideas so the examiner can follow you.';
    }
    return 'Good pace and length. Add one concrete example to make the answer more memorable.';
  }
}
