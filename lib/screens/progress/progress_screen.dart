import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, this.onStartPractice});

  final VoidCallback? onStartPractice;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final weekly = state.weeklyMinutes;
    final totalWeek = weekly.fold<int>(0, (sum, value) => sum + value);

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 122),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your progress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                state.totalSessions == 0
                    ? 'Your first call is the hardest. After that, it gets fun.'
                    : 'Every conversation is quietly changing how you speak.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (state.totalSessions == 0) ...[
                EmptyState(
                  icon: Icons.video_call_rounded,
                  title: 'Your first call is waiting',
                  message:
                      'Pick a scenario, speak for two minutes, and this page will start filling up with scores, streak and new words.',
                  actionLabel:
                      onStartPractice == null ? null : 'Browse scenarios',
                  onAction: onStartPractice,
                ),
                const SizedBox(height: 14),
              ],
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'This week',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${totalWeek ~/ 60} min total',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _WeeklyChart(data: weekly),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.5,
                children: [
                  _Metric(
                    icon: Icons.video_call_outlined,
                    value: '${state.totalSessions}',
                    label: 'total sessions',
                    color: AppColors.purple,
                  ),
                  _Metric(
                    icon: Icons.timer_outlined,
                    value: AppUtils.readableMinutes(state.totalMinutes),
                    label: 'speaking time',
                    color: AppColors.mintDeep,
                  ),
                  _Metric(
                    icon: Icons.speed_rounded,
                    value: state.averageFluency == 0
                        ? '—'
                        : '${state.averageFluency}',
                    label: 'avg fluency',
                    color: AppColors.violet,
                  ),
                  _Metric(
                    icon: Icons.record_voice_over_rounded,
                    value: state.bestPronunciation == 0
                        ? '—'
                        : '${state.bestPronunciation}',
                    label: 'best pronunciation',
                    color: AppColors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionHeader(
                title: 'Achievements',
                subtitle: 'Little badges for showing up',
              ),
              ...Catalog.achievements.map((achievement) {
                final value = _achievementValue(achievement.id, state);
                final unlocked = value >= achievement.target;
                final progress =
                    (value / achievement.target).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: unlocked
                          ? AppColors.mintSoft.withValues(alpha: 0.55)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: unlocked
                            ? AppColors.mint.withValues(alpha: 0.24)
                            : Colors.white,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: unlocked
                                ? AppColors.mint
                                : AppColors.pale.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            achievement.icon,
                            size: 20,
                            color: unlocked ? Colors.white : AppColors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      achievement.title,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    unlocked
                                        ? 'Unlocked'
                                        : '${math.min(value, achievement.target)}/${achievement.target}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: unlocked
                                          ? AppColors.mintDeep
                                          : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                achievement.description,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: AppColors.pale,
                                  valueColor: AlwaysStoppedAnimation(
                                    unlocked
                                        ? AppColors.mint
                                        : AppColors.lavender,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              const SectionHeader(
                title: 'Recent sessions',
                subtitle: 'A record of you showing up',
              ),
              if (state.sessions.isEmpty)
                EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'No sessions yet',
                  message:
                      'Finish a video call and your fluency, new words and streak will appear here.',
                  actionLabel:
                      onStartPractice == null ? null : 'Start practising',
                  onAction: onStartPractice,
                )
              else
                ...state.sessions.take(8).map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _HistoryTile(session: session),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  int _achievementValue(String id, AppState state) {
    return switch (id) {
      'first-call' => state.totalSessions,
      'streak-3' => state.streak,
      'streak-7' => state.streak,
      'ten-calls' => state.totalSessions,
      'pron-90' => state.bestPronunciation,
      _ => 0,
    };
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.data});

  final List<int> data;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, data.fold<int>(0, math.max));
    final today = DateTime.now();
    return SizedBox(
      height: 128,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = data[index];
                final height = 8 + (value / maxValue) * 76;
                final day = today.subtract(Duration(days: 6 - index));
                final isToday = index == 6;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value == 0 ? '' : '${value ~/ 60}',
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 6, end: height),
                        duration: Duration(milliseconds: 650 + index * 60),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedHeight, _) => Container(
                          width: 20,
                          height: animatedHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [
                                      AppColors.mint,
                                      const Color(0xFF6EE7B7),
                                    ]
                                  : [
                                      AppColors.violet,
                                      AppColors.lavender,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _days[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday
                              ? AppColors.mintDeep
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.deep.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.session});

  final SessionRecord session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.pale,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.video_call_outlined,
                size: 18, color: AppColors.purple),
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
                  '${AppUtils.shortDate(session.date)} • ${AppUtils.readableMinutes(session.durationSeconds)} • ${session.words} words',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          ScoreRing(
            value: session.fluency / 100,
            size: 40,
            stroke: 4,
            color: AppColors.mint,
            background: AppColors.pale,
          ),
        ],
      ),
    );
  }
}
