import 'package:flutter_test/flutter_test.dart';

import 'package:ai_speaking_partner/data/catalog.dart';
import 'package:ai_speaking_partner/data/demo_ai.dart';
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
}
