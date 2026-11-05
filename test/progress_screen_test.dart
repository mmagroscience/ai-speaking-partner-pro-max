import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_speaking_partner/core/app_theme.dart';
import 'package:ai_speaking_partner/screens/progress/progress_screen.dart';
import 'package:ai_speaking_partner/services/secure_store.dart';
import 'package:ai_speaking_partner/state/app_state.dart';

void main() {
  setUp(() => SecureStore.disabled = true);

  testWidgets('empty progress shows a first-call action', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'name': 'Foysal',
      'goal': 'everydayEnglish',
      'level': 'intermediate',
      'helpLanguage': 'english',
    });
    final state = await AppState.create();
    var tapped = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ProgressScreen(onStartPractice: () => tapped = true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Your first call is waiting'), findsOneWidget);
    await tester.tap(find.text('Browse scenarios'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
