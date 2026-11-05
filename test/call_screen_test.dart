import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_speaking_partner/core/app_theme.dart';
import 'package:ai_speaking_partner/data/catalog.dart';
import 'package:ai_speaking_partner/screens/call/call_screen.dart';
import 'package:ai_speaking_partner/services/secure_store.dart';
import 'package:ai_speaking_partner/state/app_state.dart';

void main() {
  setUp(() => SecureStore.disabled = true);

  testWidgets('call screen opens with the AI line and controls', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'name': 'Foysal',
      'goal': 'everydayEnglish',
      'level': 'intermediate',
      'helpLanguage': 'english',
      'autoSpeak': false,
    });
    final state = await AppState.create();
    final scenario = Catalog.scenarios.first;
    final persona = Catalog.personaById(scenario.personaId);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: CallScreen(scenario: scenario, persona: persona),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();

    expect(find.text(scenario.openingLine), findsOneWidget);
    expect(find.text('Speak'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call_end_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('Call ended'), findsOneWidget);
    expect(find.textContaining('fluency'), findsOneWidget);
  });
}
