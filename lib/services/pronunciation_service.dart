import 'dart:math' as math;

import '../data/models.dart';

class PronunciationService {
  PronunciationService._();

  static PronunciationResult evaluate(Phrase phrase, String transcript) {
    final expected = _tokens(phrase.text);
    final spoken = _tokens(transcript);
    final used = List<bool>.filled(spoken.length, false);
    final scores = <WordScore>[];

    for (final word in expected) {
      var exactIndex = -1;
      for (var i = 0; i < spoken.length; i++) {
        if (!used[i] && spoken[i] == word) {
          exactIndex = i;
          break;
        }
      }
      if (exactIndex >= 0) {
        used[exactIndex] = true;
        scores.add(WordScore(word: word, status: WordStatus.perfect));
        continue;
      }

      var bestIndex = -1;
      var bestDistance = 999;
      for (var i = 0; i < spoken.length; i++) {
        if (used[i]) continue;
        final distance = _levenshtein(word, spoken[i]);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = i;
        }
      }

      final threshold = word.length <= 4 ? 1 : 2;
      if (bestIndex >= 0 && bestDistance <= threshold) {
        used[bestIndex] = true;
        scores.add(WordScore(
          word: word,
          status: WordStatus.close,
          spokenAs: spoken[bestIndex],
        ));
      } else {
        scores.add(WordScore(word: word, status: WordStatus.missed));
      }
    }

    final total = scores.fold<double>(0, (sum, score) => sum + score.value);
    final percent = expected.isEmpty
        ? 0
        : (total / expected.length * 100).round().clamp(0, 100);

    return PronunciationResult(
      phrase: phrase.text,
      transcript: transcript,
      words: scores,
      score: percent,
    );
  }

  static PronunciationResult demo(Phrase phrase) {
    final words = _tokens(phrase.text)
        .map((w) => WordScore(word: w, status: WordStatus.perfect))
        .toList();
    return PronunciationResult(
      phrase: phrase.text,
      transcript: phrase.text,
      words: words,
      score: 100,
    );
  }

  static String feedback(PronunciationResult result) {
    if (result.score >= 92) {
      return 'Excellent! Your sounds are clear and the rhythm feels natural. Try a slightly faster pace next.';
    }
    if (result.score >= 80) {
      return 'Great job. A few words need a little more clarity — listen once more and stress the underlined sounds.';
    }
    if (result.score >= 60) {
      return 'Good attempt. Slow down and break the phrase into two short chunks, then join them again.';
    }
    return 'Keep going — this phrase has some tricky sounds. Listen to the model, repeat each word, then say the full sentence.';
  }

  static List<String> _tokens(String text) {
    var normalized = text.toLowerCase().replaceAll('’', "'");
    const contractions = {
      "i'm": 'i am',
      "i've": 'i have',
      "i'll": 'i will',
      "i'd": 'i would',
      "don't": 'do not',
      "doesn't": 'does not',
      "didn't": 'did not',
      "can't": 'cannot',
      "won't": 'will not',
      "isn't": 'is not',
      "aren't": 'are not',
      "wasn't": 'was not',
      "weren't": 'were not',
      "haven't": 'have not',
      "hasn't": 'has not',
      "wouldn't": 'would not',
      "couldn't": 'could not',
      "shouldn't": 'should not',
      "let's": 'let us',
    };
    contractions.forEach((key, replacement) {
      normalized = normalized.replaceAll(key, replacement);
    });
    return RegExp(r"[a-z0-9']+")
        .allMatches(normalized)
        .map((m) => m.group(0)!)
        .toList();
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        current[j + 1] = math.min(
          math.min(current[j] + 1, previous[j + 1] + 1),
          previous[j] + cost,
        );
      }
      previous = current;
    }
    return previous[b.length];
  }
}
