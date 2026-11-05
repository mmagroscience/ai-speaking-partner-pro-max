import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_speaking_partner/data/models.dart';
import 'package:ai_speaking_partner/services/secure_store.dart';
import 'package:ai_speaking_partner/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SecureStore.disabled = true;
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'name': 'Foysal',
      'goal': 'everydayEnglish',
      'level': 'intermediate',
      'helpLanguage': 'english',
    });
  });

  test('admin PIN verifies and only accepts 4-8 digits', () async {
    final state = await AppState.create();

    expect(state.usesDefaultAdminPin, isTrue);
    expect(state.verifyAdminPin('1234'), isTrue);
    expect(state.verifyAdminPin('0000'), isFalse);

    expect(await state.setAdminPin('12'), isFalse);
    expect(await state.setAdminPin('abcd'), isFalse);
    expect(await state.setAdminPin('2468'), isTrue);
    expect(state.usesDefaultAdminPin, isFalse);
    expect(state.verifyAdminPin('2468'), isTrue);
    expect(state.verifyAdminPin('1234'), isFalse);
  });

  test('progress export/import restores sessions, streak and favourites',
      () async {
    final state = await AppState.create();
    await state.recordSession(
      SessionRecord(
        id: 'session-1',
        date: DateTime.now(),
        scenarioTitle: 'Coffee catch-up',
        personaName: 'Sarah',
        durationSeconds: 180,
        turns: 4,
        words: 64,
        fillers: 1,
        fluency: 78,
      ),
    );
    state.toggleFavorite('coffee-chat');

    final backup = state.exportProgressJson();
    expect(backup, contains('ai-speaking-partner'));

    await state.resetLearningData();
    expect(state.sessions, isEmpty);
    expect(state.totalSessions, 0);

    final error = await state.importProgressJson(backup);
    expect(error, isNull);
    expect(state.sessions, hasLength(1));
    expect(state.sessions.first.scenarioTitle, 'Coffee catch-up');
    expect(state.totalSessions, 1);
    expect(state.favorites, contains('coffee-chat'));
    expect(state.streak, 1);
    expect(state.fluency, greaterThan(0));
  });

  test('import rejects files that were not exported by this app', () async {
    final state = await AppState.create();
    final error = await state.importProgressJson('{"app":"something-else"}');
    expect(error, isNotNull);
  });
}
