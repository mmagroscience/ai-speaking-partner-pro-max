import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../services/ai_service.dart';
import '../services/ota_service.dart';
import '../services/secure_store.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _read();
    ai.setKeys(apiKeys);
  }

  static const defaultAdminPin = '1234';

  final SharedPreferences _prefs;
  final AiService ai = AiService();
  final OtaService ota = OtaService();

  bool _loaded = false;
  bool onboarded = false;
  String name = 'Friend';
  AppGoal goal = AppGoal.everydayEnglish;
  CefrLevel level = CefrLevel.beginner;
  HelpLanguage helpLanguage = HelpLanguage.english;
  String avatarBase64 = '';
  List<String> apiKeys = [];
  String otaUrl = '';
  String adminPin = defaultAdminPin;
  bool autoSpeak = true;
  bool eyeContact = true;
  int streak = 0;
  int minutesToday = 0;
  int totalMinutes = 0;
  int totalSessions = 0;
  int fluency = 0;
  int bestPronunciation = 0;
  int _otaPreviewVersion = 1;
  List<SessionRecord> sessions = [];
  Set<String> favorites = {};
  Map<int, int> kidsStars = {};
  VoiceProfile voice = const VoiceProfile();
  List<Scenario> customScenarios = [];
  DateTime? _lastSessionDay;
  DateTime? _lastActiveDay;

  bool get loaded => _loaded;

  static Future<AppState> create() async {
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(prefs);
    await state._loadSecureKeys();
    state._loaded = true;
    return state;
  }

  Future<void> _loadSecureKeys() async {
    final stored = await SecureStore.readApiKeys();
    if (stored.isNotEmpty) {
      apiKeys = stored;
      ai.setKeys(apiKeys);
      await _prefs.remove('apiKeys');
      return;
    }
    // Migrate keys that older builds left in plain-text preferences.
    if (apiKeys.isNotEmpty && await SecureStore.writeApiKeys(apiKeys)) {
      await _prefs.remove('apiKeys');
    }
  }

  bool get usesDefaultAdminPin => adminPin == defaultAdminPin;

  List<Scenario> get allScenarios => [
        ...Catalog.scenarios,
        ...customScenarios,
      ];

  Persona get customPersona => Catalog.personaById('custom').copyWith(
        name: voice.displayName.trim().isEmpty
            ? 'Familiar Person'
            : voice.displayName.trim(),
        role: voice.cloned ? 'Your cloned companion' : 'Your familiar person',
        isCustom: true,
      );

  Persona personaFor(Scenario scenario) {
    if (scenario.personaId == 'custom') return customPersona;
    return Catalog.personaById(scenario.personaId);
  }

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Friend';
    return trimmed.split(' ').first;
  }

  String get helpLabelForGoal {
    return switch (helpLanguage) {
      HelpLanguage.english => goal.blurb,
      HelpLanguage.bangla => goal.bnBlurb,
      HelpLanguage.hindi => goal.blurb,
    };
  }

  String goalLabel(AppGoal value) => switch (helpLanguage) {
        HelpLanguage.english => value.label,
        HelpLanguage.bangla => value.bnLabel,
        HelpLanguage.hindi => value.hiLabel,
      };

  int get averageFluency {
    if (sessions.isEmpty) return fluency;
    final recent = sessions.take(5);
    final avg =
        recent.fold<int>(0, (sum, item) => sum + item.fluency) / recent.length;
    return avg.round();
  }

  List<int> get weeklyMinutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<int>.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final total = sessions
          .where((s) {
            final d = DateTime(s.date.year, s.date.month, s.date.day);
            return d == day;
          })
          .fold<int>(0, (sum, s) => sum + s.durationSeconds);
      return total;
    });
  }

  List<SessionRecord> get recentSessions => sessions.take(5).toList();

  bool isFavorite(String id) => favorites.contains(id);

  int kidsStarsFor(int week) => kidsStars[week] ?? 0;

  int get kidsCompletedWeeks =>
      kidsStars.values.where((stars) => stars > 0).length;

  int get kidsNextWeek {
    for (var week = 1; week <= 8; week++) {
      if (kidsStarsFor(week) == 0) return week;
    }
    return 8;
  }

  Future<void> completeKidsWeek(int week, int stars) async {
    final safeWeek = week.clamp(1, 8).toInt();
    final safeStars = stars.clamp(2, 3).toInt();
    if (kidsStarsFor(safeWeek) >= safeStars) return;
    kidsStars = {...kidsStars, safeWeek: safeStars};
    await _prefs.setStringList(
      'kidsStars',
      kidsStars.entries.map((entry) => '${entry.key}:${entry.value}').toList(),
    );
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    _prefs.setStringList('favorites', favorites.toList());
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required AppGoal selectedGoal,
    required CefrLevel selectedLevel,
    required String selectedName,
    required HelpLanguage language,
  }) async {
    goal = selectedGoal;
    level = selectedLevel;
    name = selectedName.trim().isEmpty ? 'Friend' : selectedName.trim();
    helpLanguage = language;
    onboarded = true;
    await Future.wait([
      _prefs.setBool('onboarded', true),
      _prefs.setString('goal', goal.name),
      _prefs.setString('level', level.name),
      _prefs.setString('name', name),
      _prefs.setString('helpLanguage', helpLanguage.name),
    ]);
    notifyListeners();
  }

  Future<void> setName(String value) async {
    name = value.trim().isEmpty ? 'Friend' : value.trim();
    await _prefs.setString('name', name);
    notifyListeners();
  }

  Future<void> setGoal(AppGoal value) async {
    goal = value;
    await _prefs.setString('goal', goal.name);
    notifyListeners();
  }

  Future<void> setLevel(CefrLevel value) async {
    level = value;
    await _prefs.setString('level', level.name);
    notifyListeners();
  }

  Future<void> setHelpLanguage(HelpLanguage value) async {
    helpLanguage = value;
    await _prefs.setString('helpLanguage', helpLanguage.name);
    notifyListeners();
  }

  Future<void> setAvatarBase64(String value) async {
    avatarBase64 = value;
    await _prefs.setString('avatar', avatarBase64);
    notifyListeners();
  }

  Future<void> setVoiceProfile(VoiceProfile value) async {
    voice = value;
    await _prefs.setString('voiceProfile', jsonEncode({
      'displayName': voice.displayName,
      'photoBase64': voice.photoBase64,
      'voiceFileName': voice.voiceFileName,
      'cloned': voice.cloned,
    }));
    notifyListeners();
  }

  Future<void> setAutoSpeak(bool value) async {
    autoSpeak = value;
    await _prefs.setBool('autoSpeak', value);
    notifyListeners();
  }

  Future<void> setEyeContact(bool value) async {
    eyeContact = value;
    await _prefs.setBool('eyeContact', value);
    notifyListeners();
  }

  Future<void> setOtaUrl(String value) async {
    otaUrl = value.trim();
    await _prefs.setString('otaUrl', otaUrl);
    notifyListeners();
  }

  bool verifyAdminPin(String value) => value.trim() == adminPin;

  Future<bool> setAdminPin(String value) async {
    final clean = value.trim();
    if (!RegExp(r'^\d{4,8}$').hasMatch(clean)) return false;
    adminPin = clean;
    await _prefs.setString('adminPin', adminPin);
    notifyListeners();
    return true;
  }

  Future<void> addApiKey(String key) async {
    final clean = key.trim();
    if (clean.isEmpty || apiKeys.contains(clean)) return;
    apiKeys = [...apiKeys, clean];
    ai.setKeys(apiKeys);
    await _persistApiKeys();
    notifyListeners();
  }

  Future<void> removeApiKey(String key) async {
    apiKeys = apiKeys.where((k) => k != key).toList();
    ai.setKeys(apiKeys);
    await _persistApiKeys();
    notifyListeners();
  }

  Future<void> _persistApiKeys() async {
    final secure = await SecureStore.writeApiKeys(apiKeys);
    if (secure) {
      await _prefs.remove('apiKeys');
    } else {
      await _prefs.setStringList('apiKeys', apiKeys);
    }
  }

  Future<void> addCustomScenario(Scenario scenario) async {
    customScenarios = [...customScenarios, scenario];
    await _saveCustomScenarios();
    notifyListeners();
  }

  Future<void> removeCustomScenario(String id) async {
    customScenarios = customScenarios.where((s) => s.id != id).toList();
    await _saveCustomScenarios();
    notifyListeners();
  }

  Future<void> _saveCustomScenarios() async {
    await _prefs.setString(
      'customScenarios',
      jsonEncode(customScenarios.map(_scenarioToJson).toList()),
    );
  }

  Map<String, dynamic> _scenarioToJson(Scenario s) => {
        'id': s.id,
        'title': s.title,
        'subtitle': s.subtitle,
        'category': s.category,
        'description': s.description,
        'aiRole': s.aiRole,
        'openingLine': s.openingLine,
        'emoji': s.emoji,
        'level': s.level.name,
        'goals': s.goals,
        'personaId': s.personaId,
      };

  Scenario _scenarioFromJson(Map raw) {
    final item = raw.cast<String, dynamic>();
    return Scenario(
      id: item['id'] as String? ?? 'custom-${item.hashCode}',
      title: item['title'] as String? ?? 'Custom practice',
      subtitle: item['subtitle'] as String? ?? 'Your own scenario',
      category: item['category'] as String? ?? 'Everyday English',
      description: item['description'] as String? ?? '',
      aiRole: item['aiRole'] as String? ?? 'A friendly conversation partner',
      openingLine:
          item['openingLine'] as String? ?? 'Hey! Let\'s practise together.',
      emoji: item['emoji'] as String? ?? '✨',
      level: CefrLevel.values.firstWhere(
        (l) => l.name == item['level'],
        orElse: () => CefrLevel.intermediate,
      ),
      goals: (item['goals'] as List?)?.cast<String>() ??
          const ['Keep the conversation going'],
      colors: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      personaId: item['personaId'] as String? ?? 'sarah',
    );
  }

  /// A portable snapshot the learner can copy to the clipboard or a file.
  String exportProgressJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'ai-speaking-partner',
      'schema': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': {
        'name': name,
        'goal': goal.name,
        'level': level.name,
        'helpLanguage': helpLanguage.name,
      },
      'stats': {
        'streak': streak,
        'minutesToday': minutesToday,
        'totalMinutes': totalMinutes,
        'totalSessions': totalSessions,
        'bestPronunciation': bestPronunciation,
        'lastSessionDay': _lastSessionDay?.toIso8601String() ?? '',
      },
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'favorites': favorites.toList(),
      'kidsStars': kidsStars.map((key, value) => MapEntry('$key', value)),
      'customScenarios': customScenarios.map(_scenarioToJson).toList(),
    });
  }

  /// Returns `null` on success or a short, user-facing error message.
  Future<String?> importProgressJson(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return 'That is not a progress backup.';
      final data = decoded.cast<String, dynamic>();
      if (data['app'] != 'ai-speaking-partner') {
        return 'That file was not exported by this app.';
      }

      final importedSessions = <SessionRecord>[];
      final rawSessions = data['sessions'];
      if (rawSessions is List) {
        for (final item in rawSessions.whereType<Map>()) {
          importedSessions.add(
            SessionRecord.fromJson(item.cast<String, dynamic>()),
          );
        }
      }

      sessions = importedSessions.take(60).toList();
      totalSessions = sessions.length;
      totalMinutes = sessions.fold<int>(
        0,
        (sum, session) => sum + (session.durationSeconds ~/ 60),
      );

      final stats = data['stats'];
      if (stats is Map) {
        streak = (stats['streak'] as num?)?.toInt() ?? 0;
        minutesToday = (stats['minutesToday'] as num?)?.toInt() ?? 0;
        bestPronunciation =
            (stats['bestPronunciation'] as num?)?.toInt() ?? 0;
        final last = stats['lastSessionDay'] as String? ?? '';
        _lastSessionDay = DateTime.tryParse(last);
      }
      if (_lastSessionDay == null && sessions.isNotEmpty) {
        _lastSessionDay = sessions.first.date;
      }
      _lastActiveDay = _lastSessionDay;
      fluency = averageFluency;

      final profile = data['profile'];
      if (profile is Map) {
        final importedName = profile['name'] as String?;
        if (importedName != null && importedName.trim().isNotEmpty) {
          name = importedName.trim();
          await _prefs.setString('name', name);
        }
        final importedGoal = profile['goal'] as String?;
        goal = AppGoal.values.firstWhere(
          (value) => value.name == importedGoal,
          orElse: () => goal,
        );
        final importedLevel = profile['level'] as String?;
        level = CefrLevel.values.firstWhere(
          (value) => value.name == importedLevel,
          orElse: () => level,
        );
        final importedHelp = profile['helpLanguage'] as String?;
        helpLanguage = HelpLanguage.values.firstWhere(
          (value) => value.name == importedHelp,
          orElse: () => helpLanguage,
        );
        await Future.wait([
          _prefs.setString('goal', goal.name),
          _prefs.setString('level', level.name),
          _prefs.setString('helpLanguage', helpLanguage.name),
        ]);
      }

      final importedFavorites = data['favorites'];
      if (importedFavorites is List) {
        favorites = importedFavorites.whereType<String>().toSet();
        await _prefs.setStringList('favorites', favorites.toList());
      }

      final importedKids = data['kidsStars'];
      if (importedKids is Map) {
        kidsStars = {
          for (final entry in importedKids.entries)
            if (int.tryParse('${entry.key}') != null &&
                entry.value is num &&
                (entry.value as num).toInt() > 0)
              int.parse('${entry.key}'): (entry.value as num).toInt().clamp(1, 3).toInt(),
        };
        await _prefs.setStringList(
          'kidsStars',
          kidsStars.entries
              .map((entry) => '${entry.key}:${entry.value}')
              .toList(),
        );
      }

      final importedScenarios = data['customScenarios'];
      if (importedScenarios is List) {
        customScenarios = importedScenarios.whereType<Map>().map(_scenarioFromJson).toList();
        await _saveCustomScenarios();
      }

      await _persistStats();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not read that progress backup.';
    }
  }

  Future<void> recordSession(SessionRecord session) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minutes = math.max(1, session.durationSeconds ~/ 60);

    if (_lastSessionDay == null) {
      streak = 1;
      minutesToday = minutes;
    } else {
      final last = DateTime(
          _lastSessionDay!.year, _lastSessionDay!.month, _lastSessionDay!.day);
      final diff = today.difference(last).inDays;
      if (diff == 0) {
        if (streak == 0) streak = 1;
        minutesToday += minutes;
      } else {
        minutesToday = minutes;
        streak = diff == 1 ? streak + 1 : 1;
      }
    }

    _lastSessionDay = today;
    _lastActiveDay = today;
    totalMinutes += minutes;
    totalSessions += 1;
    sessions = [session, ...sessions].take(60).toList();
    fluency = averageFluency;
    await _persistStats();
    notifyListeners();
  }

  Future<void> recordPronunciationScore(int score) async {
    if (score > bestPronunciation) {
      bestPronunciation = score;
      await _prefs.setInt('bestPronunciation', bestPronunciation);
      notifyListeners();
    }
  }

  Future<void> _persistStats() async {
    await Future.wait([
      _prefs.setInt('streak', streak),
      _prefs.setInt('minutesToday', minutesToday),
      _prefs.setInt('totalMinutes', totalMinutes),
      _prefs.setInt('totalSessions', totalSessions),
      _prefs.setInt('fluency', fluency),
      _prefs.setString('lastSessionDay', _lastSessionDay?.toIso8601String() ?? ''),
      _prefs.setString('lastActiveDay', _lastActiveDay?.toIso8601String() ?? ''),
      _prefs.setString(
        'sessions',
        jsonEncode(sessions.map((s) => s.toJson()).toList()),
      ),
    ]);
  }

  String buildOtaJson({
    required int versionCode,
    required String versionName,
    required String apkUrl,
    required String changelog,
    required bool forceUpdate,
  }) {
    _otaPreviewVersion = versionCode;
    final config = OtaConfig(
      latestVersionCode: versionCode,
      latestVersionName: versionName,
      apkUrl: apkUrl,
      changelog: changelog,
      forceUpdate: forceUpdate,
      notice: 'Published from the in-app admin panel.',
    );
    notifyListeners();
    return const JsonEncoder.withIndent('  ').convert(config.toJson());
  }

  OtaConfig get previewOtaConfig => OtaConfig(
        latestVersionCode: _otaPreviewVersion,
        latestVersionName: '1.0.$_otaPreviewVersion',
        apkUrl: 'https://example.com/ai-speaking-partner.apk',
        changelog:
            'New practice topics, smoother video calls, and pronunciation fixes.',
        forceUpdate: false,
      );

  Future<void> resetLearningData() async {
    sessions = [];
    streak = 0;
    minutesToday = 0;
    totalMinutes = 0;
    totalSessions = 0;
    fluency = 0;
    bestPronunciation = 0;
    kidsStars = {};
    _lastSessionDay = null;
    _lastActiveDay = null;
    await Future.wait([
      _prefs.remove('sessions'),
      _prefs.remove('streak'),
      _prefs.remove('minutesToday'),
      _prefs.remove('totalMinutes'),
      _prefs.remove('totalSessions'),
      _prefs.remove('fluency'),
      _prefs.remove('bestPronunciation'),
      _prefs.remove('kidsStars'),
      _prefs.remove('lastSessionDay'),
      _prefs.remove('lastActiveDay'),
    ]);
    notifyListeners();
  }

  Future<void> resetEverything() async {
    await SecureStore.clear();
    await _prefs.clear();
    onboarded = false;
    name = 'Friend';
    goal = AppGoal.everydayEnglish;
    level = CefrLevel.beginner;
    helpLanguage = HelpLanguage.english;
    avatarBase64 = '';
    apiKeys = [];
    ai.setKeys(apiKeys);
    otaUrl = '';
    adminPin = defaultAdminPin;
    autoSpeak = true;
    eyeContact = true;
    streak = 0;
    minutesToday = 0;
    totalMinutes = 0;
    totalSessions = 0;
    fluency = 0;
    bestPronunciation = 0;
    sessions = [];
    favorites = {};
    kidsStars = {};
    voice = const VoiceProfile();
    customScenarios = [];
    _lastSessionDay = null;
    _lastActiveDay = null;
    notifyListeners();
  }

  void _read() {
    onboarded = _prefs.getBool('onboarded') ?? false;
    name = _prefs.getString('name') ?? 'Friend';
    goal = AppGoal.values.firstWhere(
      (g) => g.name == _prefs.getString('goal'),
      orElse: () => AppGoal.everydayEnglish,
    );
    level = CefrLevel.values.firstWhere(
      (l) => l.name == _prefs.getString('level'),
      orElse: () => CefrLevel.beginner,
    );
    helpLanguage = HelpLanguage.values.firstWhere(
      (l) => l.name == _prefs.getString('helpLanguage'),
      orElse: () => HelpLanguage.english,
    );
    avatarBase64 = _prefs.getString('avatar') ?? '';
    apiKeys = _prefs.getStringList('apiKeys') ?? [];
    otaUrl = _prefs.getString('otaUrl') ?? '';
    adminPin = _prefs.getString('adminPin') ?? defaultAdminPin;
    autoSpeak = _prefs.getBool('autoSpeak') ?? true;
    eyeContact = _prefs.getBool('eyeContact') ?? true;
    streak = _prefs.getInt('streak') ?? 0;
    minutesToday = _prefs.getInt('minutesToday') ?? 0;
    totalMinutes = _prefs.getInt('totalMinutes') ?? 0;
    totalSessions = _prefs.getInt('totalSessions') ?? 0;
    fluency = _prefs.getInt('fluency') ?? 0;
    bestPronunciation = _prefs.getInt('bestPronunciation') ?? 0;
    favorites = (_prefs.getStringList('favorites') ?? []).toSet();
    kidsStars = {
      for (final entry in _prefs.getStringList('kidsStars') ?? const [])
        if (entry.contains(':'))
          if (int.tryParse(entry.split(':').first) != null &&
              int.tryParse(entry.split(':').last) != null)
            int.parse(entry.split(':').first):
                int.parse(entry.split(':').last).clamp(1, 3).toInt(),
    };
    _lastSessionDay = DateTime.tryParse(_prefs.getString('lastSessionDay') ?? '');
    _lastActiveDay = DateTime.tryParse(_prefs.getString('lastActiveDay') ?? '');

    final rawSessions = _prefs.getString('sessions');
    if (rawSessions != null && rawSessions.isNotEmpty) {
      try {
        final list = jsonDecode(rawSessions);
        if (list is List) {
          sessions = list
              .whereType<Map>()
              .map((item) => SessionRecord.fromJson(item.cast<String, dynamic>()))
              .toList();
        }
      } catch (_) {}
    }

    final rawVoice = _prefs.getString('voiceProfile');
    if (rawVoice != null && rawVoice.isNotEmpty) {
      try {
        final map = jsonDecode(rawVoice);
        if (map is Map) {
          voice = VoiceProfile(
            displayName: map['displayName'] as String? ?? 'Familiar Person',
            photoBase64: map['photoBase64'] as String? ?? '',
            voiceFileName: map['voiceFileName'] as String? ?? '',
            cloned: map['cloned'] as bool? ?? false,
          );
        }
      } catch (_) {}
    }

    final rawScenarios = _prefs.getString('customScenarios');
    if (rawScenarios != null && rawScenarios.isNotEmpty) {
      try {
        final list = jsonDecode(rawScenarios);
        if (list is List) {
          customScenarios =
              list.whereType<Map>().map(_scenarioFromJson).toList();
        }
      } catch (_) {}
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastActiveDay == null) {
      minutesToday = 0;
    } else {
      final last = DateTime(
          _lastActiveDay!.year, _lastActiveDay!.month, _lastActiveDay!.day);
      if (today.difference(last).inDays > 0) minutesToday = 0;
    }
    if (_lastSessionDay != null) {
      final last = DateTime(_lastSessionDay!.year, _lastSessionDay!.month,
          _lastSessionDay!.day);
      if (today.difference(last).inDays > 1) streak = 0;
    }
  }
}
