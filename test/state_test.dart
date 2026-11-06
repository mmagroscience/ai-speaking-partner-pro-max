import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_speaking_partner/data/flashcard_models.dart';
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

  test('kids lesson stars are saved and never downgraded', () async {
    final state = await AppState.create();

    expect(state.kidsCompletedWeeks, 0);
    expect(state.kidsNextWeek, 1);

    await state.completeKidsWeek(1, 2);
    expect(state.kidsStarsFor(1), 2);
    expect(state.kidsNextWeek, 2);
    expect(state.kidsCompletedWeeks, 1);

    await state.completeKidsWeek(1, 3);
    expect(state.kidsStarsFor(1), 3);

    await state.completeKidsWeek(1, 2);
    expect(state.kidsStarsFor(1), 3);

    await state.completeKidsWeek(9, 3);
    expect(state.kidsStarsFor(8), 3);
    expect(state.kidsNextWeek, 2);
  });

  test('kids progress travels with the backup file', () async {
    final state = await AppState.create();
    await state.completeKidsWeek(2, 3);

    final backup = state.exportProgressJson();
    await state.resetLearningData();
    expect(state.kidsStarsFor(2), 0);

    expect(await state.importProgressJson(backup), isNull);
    expect(state.kidsStarsFor(2), 3);
    expect(state.kidsCompletedWeeks, 1);
  });

  test('flashcard level, known and seen words are saved', () async {
    final state = await AppState.create();

    expect(state.studyLevel, StudyLevel.class5);
    expect(state.flashKnown, isEmpty);

    await state.setStudyLevel(StudyLevel.university);
    await state.markFlashSeen('Believe');
    await state.setFlashKnown('believe', true);
    await state.completeFlashDeck();

    expect(state.studyLevel, StudyLevel.university);
    expect(state.hasSeenFlash('BELIEVE'), isTrue);
    expect(state.isFlashKnown('Believe'), isTrue);
    expect(state.flashDecks, 1);

    await state.setFlashKnown('believe', false);
    expect(state.isFlashKnown('believe'), isFalse);

    await state.setFlashKnown('believe', true);
    final backup = state.exportProgressJson();
    await state.resetLearningData();
    expect(state.isFlashKnown('believe'), isFalse);
    expect(state.flashDecks, 0);

    expect(await state.importProgressJson(backup), isNull);
    expect(state.studyLevel, StudyLevel.university);
    expect(state.isFlashKnown('believe'), isTrue);
    expect(state.hasSeenFlash('believe'), isTrue);
    expect(state.flashDecks, 1);
  });
}
