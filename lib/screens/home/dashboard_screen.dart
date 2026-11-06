import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/catalog.dart';
import '../../data/flashcard_models.dart';
import '../../data/kids_catalog.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/scenario_card.dart';
import '../../widgets/talking_avatar.dart';
import '../call/incoming_call_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../kids/kids_screen.dart';
import '../practice/ielts_screen.dart';
import '../practice/pronunciation_screen.dart';
import '../practice/vocabulary_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final persona = Catalog.personaById('sarah');
    final recommended = _recommendedScenarios(state);
    final word = _wordOfTheDay();
    final progress = (state.minutesToday / 5).clamp(0.0, 1.0);

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 122),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state),
              const SizedBox(height: 18),
              _HeroCard(
                onStart: () => _startCall(context, state),
                persona: persona,
                level: state.level,
                goal: state.goal,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.local_fire_department_rounded,
                      value: state.streak == 0 ? '0' : '${state.streak}',
                      label: 'day streak',
                      color: AppColors.amber,
                      background: const Color(0xFFFFFBF2),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: StatCard(
                      icon: Icons.timer_outlined,
                      value: '${state.minutesToday}',
                      label: 'min today',
                      color: AppColors.mintDeep,
                      background: const Color(0xFFF4FDF9),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: StatCard(
                      icon: Icons.speed_rounded,
                      value: state.averageFluency == 0
                          ? '—'
                          : '${state.averageFluency}',
                      label: 'fluency',
                      color: AppColors.violet,
                      background: const Color(0xFFFBF8FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DailyChallenge(
                minutes: state.minutesToday,
                progress: progress,
                onStart: () => _startCall(context, state),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Quick practice',
                subtitle: 'Small wins, every day',
                actionLabel: 'See all',
                onAction: () => onOpenTab(1),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.52,
                children: [
                  _QuickTile(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Pronunciation',
                    subtitle: 'Word-by-word coach',
                    colors: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PronunciationScreen(),
                      ),
                    ),
                  ),
                  _QuickTile(
                    icon: Icons.workspace_premium_rounded,
                    title: 'IELTS mock',
                    subtitle: 'Band estimate',
                    colors: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IeltsScreen()),
                    ),
                  ),
                  _QuickTile(
                    icon: Icons.auto_stories_rounded,
                    title: 'Vocabulary',
                    subtitle: '3 tones + quiz',
                    colors: const [Color(0xFF34D399), Color(0xFF059669)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VocabularyScreen(),
                      ),
                    ),
                  ),
                  _QuickTile(
                    icon: Icons.style_rounded,
                    title: 'Flashcards',
                    subtitle: 'Oxford 3000',
                    colors: const [Color(0xFF818CF8), Color(0xFF4338CA)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FlashcardsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CardsBanner(
                level: state.studyLevel,
                known: state.flashKnown.length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _KidsBanner(
                completed: state.kidsCompletedWeeks,
                total: KidsCatalog.weeks.length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KidsScreen()),
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Recommended for you',
                subtitle: 'Based on ${state.goal.label.toLowerCase()}',
                actionLabel: 'All',
                onAction: () => onOpenTab(1),
              ),
              ...recommended.map(
                (scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ScenarioCard(
                    scenario: scenario,
                    persona: state.personaFor(scenario),
                    onTap: () => _startCall(context, state, scenario: scenario),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _WordOfDay(word: word),
              if (state.recentSessions.isNotEmpty) ...[
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Recent sessions',
                  actionLabel: 'Progress',
                  onAction: () => onOpenTab(2),
                ),
                ...state.recentSessions.take(3).map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SessionTile(session: session),
                      ),
                    ),
              ],
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '5 minutes a day beats one long session.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted.withValues(alpha: 0.7),
                        fontSize: 10.5,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${state.firstName} 👋',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  LevelPill(level: state.level),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '• ${state.goal.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => onOpenTab(3),
          child: UserAvatar(
            base64: state.avatarBase64,
            name: state.firstName,
            size: 48,
          ),
        ),
      ],
    );
  }

  List<Scenario> _recommendedScenarios(AppState state) {
    final matching = state.allScenarios
        .where((s) => s.category == state.goal.category)
        .toList();
    final result = [...matching];
    for (final scenario in state.allScenarios) {
      if (result.length >= 3) break;
      if (!result.any((s) => s.id == scenario.id)) result.add(scenario);
    }
    return result.take(3).toList();
  }

  WordItem _wordOfTheDay() {
    final days = DateTime.now().difference(DateTime(2024)).inDays;
    return WordItem(Catalog.vocabulary[days % Catalog.vocabulary.length]);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _startCall(BuildContext context, AppState state, {Scenario? scenario}) {
    final selected = scenario ??
        state.allScenarios.firstWhere(
          (s) => s.category == state.goal.category,
          orElse: () => state.allScenarios.first,
        );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          scenario: selected,
          persona: state.personaFor(selected),
        ),
      ),
    );
  }
}

class WordItem {
  const WordItem(this.word);
  final VocabWord word;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.onStart,
    required this.persona,
    required this.level,
    required this.goal,
  });

  final VoidCallback onStart;
  final Persona persona;
  final CefrLevel level;
  final AppGoal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -55,
            right: -35,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint.withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.mint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'FACE-TO-FACE VIDEO CALL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Pill(
                    label: level.label,
                    color: Colors.white,
                    background: Colors.white.withValues(alpha: 0.14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Let\'s talk about\nyour day',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.13,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${persona.name} • ${persona.role} • ${persona.accent}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 10.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  TalkingAvatar(
                    persona: persona,
                    size: 100,
                    showRings: false,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onStart,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_call_rounded,
                            color: AppColors.purple, size: 21),
                        SizedBox(width: 8),
                        Text(
                          'Start speaking',
                          style: TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            color: AppColors.purple, size: 17),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'AI camera • eye contact • live subtitles',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyChallenge extends StatelessWidget {
  const _DailyChallenge({
    required this.minutes,
    required this.progress,
    required this.onStart,
  });

  final int minutes;
  final double progress;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final remaining = (5 - minutes).clamp(0, 5);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.pale,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.mint),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.ink,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'min',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily 5-minute challenge',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  remaining == 0
                      ? 'Challenge complete. A little more practice?'
                      : '$remaining min left — one short call is enough.',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.mintSoft,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onStart,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                child: Text(
                  'Start',
                  style: TextStyle(
                    color: AppColors.mintDeep,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: AppColors.deep.withValues(alpha: 0.045),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        height: 1.25,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardsBanner extends StatelessWidget {
  const _CardsBanner({
    required this.level,
    required this.known,
    required this.onTap,
  });

  final StudyLevel level;
  final int known;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF6D28D9)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 50,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 8,
                      top: 4,
                      child: _MiniCard(
                        color: const Color(0xFFFBBF24),
                        angle: -0.18,
                      ),
                    ),
                    Positioned(
                      left: 3,
                      top: 9,
                      child: _MiniCard(
                        color: const Color(0xFFA78BFA),
                        angle: 0.1,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 14,
                      child: _MiniCard(
                        color: Colors.white,
                        angle: 0,
                        letter: 'Aa',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Oxford 3000 Flashcards',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Baby → University • IPA + examples',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.label} selected • $known known · tap to study',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.66),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.color,
    required this.angle,
    this.letter,
  });

  final Color color;
  final double angle;
  final String? letter;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 34,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter ?? '',
            style: const TextStyle(
              color: AppColors.deep,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _KidsBanner extends StatelessWidget {
  const _KidsBanner({
    required this.completed,
    required this.total,
    required this.onTap,
  });

  final int completed;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: AppColors.mintGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.mint.withValues(alpha: 0.26),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🧸', style: TextStyle(fontSize: 23)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Kids · School Starter',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '8-week step-by-step plan • 10 min a day',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed/$total weeks done · tap to open',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordOfDay extends StatelessWidget {
  const _WordOfDay({required this.word});

  final WordItem word;

  @override
  Widget build(BuildContext context) {
    final item = word.word;
    return GlassCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VocabularyScreen()),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: Color(0xFFB45309), size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Word of the day',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.amber.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Pill(
                      label: item.tone.shortLabel,
                      color: AppColors.purple,
                      fontSize: 8.5,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.word}  ${item.phonetic}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.meaningBn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SessionRecord session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.pale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.video_call_outlined,
                size: 17, color: AppColors.purple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.scenarioTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${AppUtils.shortDate(session.date)} • ${AppUtils.readableMinutes(session.durationSeconds)} • ${session.turns} turns',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Pill(
            label: '${session.fluency}',
            icon: Icons.speed_rounded,
            color: AppColors.mintDeep,
            background: AppColors.mintSoft,
          ),
        ],
      ),
    );
  }
}
