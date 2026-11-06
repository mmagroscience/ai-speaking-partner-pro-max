import 'package:flutter_test/flutter_test.dart';

import 'package:ai_speaking_partner/data/catalog.dart';
import 'package:ai_speaking_partner/data/demo_ai.dart';
import 'package:ai_speaking_partner/data/flashcard_models.dart';
import 'package:ai_speaking_partner/data/kids_catalog.dart';
import 'package:ai_speaking_partner/data/models.dart';
import 'package:ai_speaking_partner/services/flashcard_service.dart';

void main() {
  test('catalog has scenarios, personas and valid links', () {
    expect(Catalog.scenarios, isNotEmpty);
    expect(Catalog.personas, isNotEmpty);
    expect(Catalog.phrases, isNotEmpty);
    expect(Catalog.vocabulary, isNotEmpty);

    for (final scenario in Catalog.scenarios) {
      expect(scenario.title.trim(), isNotEmpty);
      expect(scenario.openingLine.trim(), isNotEmpty);
      expect(Catalog.personaById(scenario.personaId).name, isNotEmpty);
    }
  });

  test('offline coach replies and corrects a common mistake', () {
    final scenario = Catalog.scenarios.firstWhere((s) => s.id == 'meet-someone');
    final reply = DemoAi.reply(
      persona: Catalog.personaById(scenario.personaId),
      scenario: scenario,
      history: const [],
      userText: 'I am agree with you',
      level: CefrLevel.beginner,
      banglaMode: true,
    );

    expect(reply.reply.trim(), isNotEmpty);
    expect(reply.correction, contains('I agree'));
    expect(reply.casualTone, isNotEmpty);
    expect(reply.formalTone, isNotEmpty);
    expect(reply.idiomaticTone, isNotEmpty);
    expect(reply.banglaTip, isNotEmpty);
  });

  test('three-tone vocabulary entries are complete', () {
    for (final word in Catalog.vocabulary) {
      expect(word.word.trim(), isNotEmpty);
      expect(word.meaningBn.trim(), isNotEmpty);
      expect(word.example.trim(), isNotEmpty);
    }
  });

  test('kids plan has 8 complete weeks', () {
    expect(KidsCatalog.weeks, hasLength(8));

    for (var i = 0; i < KidsCatalog.weeks.length; i++) {
      final week = KidsCatalog.weeks[i];
      expect(week.number, i + 1);
      expect(week.title.trim(), isNotEmpty);
      expect(week.banglaTitle.trim(), isNotEmpty);
      expect(week.focus.trim(), isNotEmpty);
      expect(week.parentTip.trim(), isNotEmpty);
      expect(week.words, hasLength(6));
      expect(week.phrases, hasLength(3));
      expect(week.cardCount, 9);

      for (final word in week.words) {
        expect(word.emoji.trim(), isNotEmpty);
        expect(word.word.trim(), isNotEmpty);
        expect(word.bangla.trim(), isNotEmpty);
        expect(word.sentence.trim(), isNotEmpty);
      }
      for (final phrase in week.phrases) {
        expect(phrase.text.trim(), isNotEmpty);
        expect(phrase.bangla.trim(), isNotEmpty);
      }
    }
  });

  test('study levels cover baby through university', () {
    expect(StudyLevel.values, hasLength(14));
    expect(StudyLevel.baby.label, 'Baby');
    expect(StudyLevel.class1.label, 'Class 1');
    expect(StudyLevel.class12.label, 'Class 12');
    expect(StudyLevel.university.label, 'University');

    for (final level in StudyLevel.values) {
      expect(level.bnLabel.trim(), isNotEmpty);
      expect(level.stage.trim(), isNotEmpty);
      expect(level.colors, hasLength(2));
    }

    expect(StudyLevel.class1.band, 'a1');
    expect(StudyLevel.class6.band, 'a2');
    expect(StudyLevel.class9.band, 'b1');
    expect(StudyLevel.class12.band, 'b2');
    expect(StudyLevel.university.band, isNull);
    expect(StudyLevelX.fromName('class9'), StudyLevel.class9);
  });

  test('each class gets its own slice of the Oxford bands', () {
    final cards = <Flashcard>[
      for (var i = 0; i < 9; i++)
        Flashcard(
          word: 'a1-$i',
          type: 'noun',
          cefr: 'a1',
          phonetic: 'test',
          senses: [FlashSense(definition: 'a1 word $i')],
        ),
      for (var i = 0; i < 6; i++)
        Flashcard(
          word: 'a2-$i',
          type: 'verb',
          cefr: 'a2',
          phonetic: 'test',
          senses: [FlashSense(definition: 'a2 word $i')],
        ),
    ];
    final all = [...FlashcardService.babyDeck(), ...cards];

    expect(FlashcardService.babyDeck(), isNotEmpty);
    for (final card in FlashcardService.babyDeck()) {
      expect(card.isBaby, isTrue);
      expect(card.bangla.trim(), isNotEmpty);
      expect(card.babySentence.trim(), isNotEmpty);
      expect(card.illustration.trim(), isNotEmpty);
      expect(card.ipa, isEmpty);
    }

    expect(FlashcardService.countFor(all, StudyLevel.class1), 3);
    expect(FlashcardService.countFor(all, StudyLevel.class4), 2);
    expect(FlashcardService.countFor(all, StudyLevel.university), 15);

    for (final level in [
      StudyLevel.class1,
      StudyLevel.class2,
      StudyLevel.class3,
    ]) {
      final pool = FlashcardService.poolFor(all, level, seed: 7);
      expect(pool, hasLength(3));
      expect(pool.every((card) => card.cefr == 'a1'), isTrue);
    }

    final deck = FlashcardService.buildDeck(
      all,
      StudyLevel.class1,
      const {},
      const {},
      seed: 4,
    );
    expect(deck, hasLength(3));

    final withoutFirst = FlashcardService.buildDeck(
      all,
      StudyLevel.class1,
      {deck.first.key},
      {deck.first.key},
      seed: 4,
    );
    expect(
      withoutFirst.any((card) => card.key == deck.first.key),
      isFalse,
    );
  });

  test('card illustration prefers curated emoji over the fallback', () {
    expect(
      FlashcardEmoji.forWord('apple', 'noun'),
      '🍎',
    );
    expect(
      FlashcardEmoji.forWord('computer', 'noun'),
      '💻',
    );
    expect(
      FlashcardEmoji.forWord('beginning', 'noun'),
      '🚩',
    );
    expect(
      FlashcardEmoji.forWord('a1-word', 'verb'),
      isNotEmpty,
    );
  });
}
