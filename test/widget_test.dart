import 'package:flutter_test/flutter_test.dart';

import 'package:ai_speaking_partner/data/catalog.dart';
import 'package:ai_speaking_partner/data/demo_ai.dart';
import 'package:ai_speaking_partner/data/kids_catalog.dart';
import 'package:ai_speaking_partner/data/models.dart';

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
}
