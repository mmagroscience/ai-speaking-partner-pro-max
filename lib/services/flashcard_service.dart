import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../data/flashcard_extras.dart';
import '../data/flashcard_models.dart';
import '../data/kids_catalog.dart';

/// Loads the bundled Oxford 3000 deck and slices it into school levels.
class FlashcardService {
  FlashcardService._();

  static const assetPath = 'assets/oxford_3000.json';
  static const deckSize = 20;

  static List<Flashcard>? _all;
  static Future<List<Flashcard>>? _pending;

  static Future<List<Flashcard>> load() {
    final cached = _all;
    if (cached != null) return Future.value(cached);
    return _pending ??= _load().whenComplete(() => _pending = null);
  }

  static Future<List<Flashcard>> _load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    final cards = <Flashcard>[];

    if (decoded is List) {
      for (final item in decoded) {
        if (item is! List || item.length < 5) continue;
        final word = '${item[0]}'.trim();
        if (word.isEmpty) continue;
        final senses = <FlashSense>[];
        final rawSenses = item[4];
        if (rawSenses is List) {
          for (final sense in rawSenses) {
            if (sense is! List || sense.isEmpty) continue;
            final definition = '${sense[0]}'.trim();
            if (definition.isEmpty) continue;
            senses.add(
              FlashSense(
                definition: definition,
                example: sense.length > 1 ? '${sense[1]}'.trim() : '',
              ),
            );
          }
        }
        if (senses.isEmpty) continue;
        final extra = flashExtras[word.toLowerCase()];
        cards.add(
          Flashcard(
            word: word,
            type: '${item[1]}'.trim(),
            cefr: '${item[2]}'.trim(),
            phonetic: '${item[3]}'.trim(),
            senses: senses,
            synonyms: extra?.synonyms ?? const [],
            antonyms: extra?.antonyms ?? const [],
            phrases: extra?.phrases ?? const [],
          ),
        );
      }
    }

    _all = [...babyDeck(), ...cards];
    return _all!;
  }

  /// The 48 picture words from the kids plan, reused as first-word cards.
  static List<Flashcard> babyDeck() {
    final cards = <Flashcard>[];
    final seen = <String>{};
    for (final week in KidsCatalog.weeks) {
      for (final word in week.words) {
        final key = word.word.toLowerCase();
        if (!seen.add(key)) continue;
        cards.add(
          Flashcard(
            word: word.word,
            type: 'picture word',
            cefr: 'pre-A1',
            phonetic: '',
            senses: const [],
            bangla: word.bangla,
            emoji: word.emoji,
            babySentence: word.sentence,
          ),
        );
      }
    }
    return cards;
  }

  /// Every word that belongs to a level, in a fresh random order.
  static List<Flashcard> poolFor(
    List<Flashcard> all,
    StudyLevel level, {
    int seed = 0,
  }) {
    if (level == StudyLevel.baby) {
      return all.where((card) => card.isBaby).toList();
    }

    final oxford = all.where((card) => !card.isBaby).toList();
    List<Flashcard> source;
    final band = level.band;
    if (band == null) {
      source = [...oxford];
    } else {
      final bandWords = oxford.where((card) => card.cefr == band).toList();
      source = [
        for (var i = 0; i < bandWords.length; i++)
          if (i % level.bandParts == level.bandIndex) bandWords[i],
      ];
    }
    final random = math.Random(seed == 0 ? level.index * 977 + 11 : seed);
    source.shuffle(random);
    return source;
  }

  static int countFor(List<Flashcard> all, StudyLevel level) {
    if (level == StudyLevel.baby) {
      return all.where((card) => card.isBaby).length;
    }
    final oxford = all.where((card) => !card.isBaby).toList();
    final band = level.band;
    if (band == null) return oxford.length;
    final bandCount = oxford.where((card) => card.cefr == band).length;
    final parts = level.bandParts;
    if (parts <= 1) return bandCount;
    final base = bandCount ~/ parts;
    return level.bandIndex < bandCount % parts ? base + 1 : base;
  }

  /// Picks the next study deck, preferring words the learner has not seen.
  static List<Flashcard> buildDeck(
    List<Flashcard> all,
    StudyLevel level,
    Set<String> seen,
    Set<String> known, {
    int seed = 0,
    int size = deckSize,
  }) {
    final pool = poolFor(all, level, seed: seed);
    final fresh = <Flashcard>[];
    final review = <Flashcard>[];
    for (final card in pool) {
      if (known.contains(card.key)) continue;
      if (seen.contains(card.key)) {
        review.add(card);
      } else {
        fresh.add(card);
      }
    }
    final deck = [...fresh, ...review];
    if (deck.length <= size) return deck;
    return deck.sublist(0, size);
  }
}
