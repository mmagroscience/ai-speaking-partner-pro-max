import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/kids_catalog.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import 'kids_lesson_screen.dart';

class KidsScreen extends StatelessWidget {
  const KidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nextWeek = state.kidsNextWeek;

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderBar(
                title: 'Kids · School Starter',
                subtitle: '8 weeks • 10 minutes a day',
                onBack: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JourneyCard(
                      completed: state.kidsCompletedWeeks,
                      nextWeek: nextWeek,
                      onStart: () => _openWeek(context, nextWeek),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            emoji: '⏱️',
                            label: '10 min / day',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                            emoji: '👨‍👩‍👧',
                            label: 'Parent-led',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                            emoji: '🎒',
                            label: 'School ready',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(
                      title: 'The 8-week plan',
                      subtitle: 'Tap a week and follow the cards in order',
                      actionLabel: 'Guide',
                      onAction: () => _showParentGuide(context),
                    ),
                    ...KidsCatalog.weeks.map(
                      (week) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WeekCard(
                          week: week,
                          stars: state.kidsStarsFor(week.number),
                          isNext: week.number == nextWeek &&
                              state.kidsStarsFor(week.number) == 0,
                          onTap: () => _openWeek(context, week.number),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => _showParentGuide(context),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.amberSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.family_restroom_rounded,
                              color: Color(0xFFB45309),
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parent guide',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'The daily 10-minute routine + what to avoid',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.muted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        '৪–৬ বছরের শিশুর জন্য। পাশে বসে একসাথে করুন।',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                              color: AppColors.muted.withValues(alpha: 0.8),
                            ),
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

  void _openWeek(BuildContext context, int weekNumber) {
    final week = KidsCatalog.weekByNumber(weekNumber);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KidsLessonScreen(week: week)),
    );
  }

  void _showParentGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _ParentGuideSheet(),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.completed,
    required this.nextWeek,
    required this.onStart,
  });

  final int completed;
  final int nextWeek;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final fraction = (completed / KidsCatalog.weeks.length).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppColors.mintGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LITTLE STEPS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${KidsCatalog.weeks.length - completed} weeks left',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'One short lesson\nevery day',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 1.12,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Words first, then short sentences. No writing, no tests.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completed of ${KidsCatalog.weeks.length} weeks completed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Start',
                      style: TextStyle(
                        color: AppColors.mintDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'week $nextWeek',
                      style: const TextStyle(
                        color: AppColors.mintDeep,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppColors.mintDeep, size: 17),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.week,
    required this.stars,
    required this.isNext,
    required this.onTap,
  });

  final KidsWeek week;
  final int stars;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = stars > 0;
    return GlassCard(
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      borderColor:
          isNext ? AppColors.mint.withValues(alpha: 0.45) : Colors.white,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: week.colors),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: week.colors.last.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 23)
                  : Text(
                      '${week.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Week ${week.number} · ${week.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 6),
                      const Pill(
                        label: 'Next',
                        color: AppColors.mintDeep,
                        background: AppColors.mintSoft,
                        fontSize: 8.5,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  week.banglaTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  week.focus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.muted.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return Icon(
                    index < stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: index < stars ? AppColors.amber : AppColors.line,
                  );
                }),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParentGuideSheet extends StatelessWidget {
  const _ParentGuideSheet();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily 10-minute routine',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'প্রতিদিন একই সময়ে, পাশে বসে — মোবাইলটা শিশুর দিকে ঘুরিয়ে দিন।',
            style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          ...[
            ('1 min', 'Greeting + নিজের নাম বলুন'),
            ('3 min', 'আজকের ৩টি শব্দ — জিনিস দেখিয়ে'),
            ('3 min', 'Repeat-after-me / প্রশ্ন-উত্তর খেলা'),
            ('2 min', 'গান বা ছবির বই'),
            ('1 min', 'পুরনো শব্দ রিভিশন + প্রশংসা'),
          ].map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      row.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mintDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _GuideList(
            title: 'যা করবেন',
            color: AppColors.mintDeep,
            background: AppColors.mintSoft,
            items: const [
              'দিনে ১০–১৫ মিনিট, প্রতিদিন একই সময়ে',
              'ভুল হলে বকা নয় — শুধু ঠিকটা বলে দিন',
              'হাততালি, স্টার বা হাইফাই দিয়ে প্রশংসা করুন',
              'সপ্তাহে ২ দিন পুরনো শব্দ রিভিশন',
            ],
          ),
          const SizedBox(height: 10),
          _GuideList(
            title: 'যা করবেন না',
            color: const Color(0xFFB91C1C),
            background: const Color(0xFFFEE2E2),
            items: const [
              'একসাথে অনেক শব্দ শেখানো',
              'ব্যাকরণের নাম বলে পড়ানো',
              'অনুবাদ চাপ দেওয়া বা বারবার “আবার বলো”',
              '১৫ মিনিটের বেশি টানা বসানো',
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _GuideList extends StatelessWidget {
  const _GuideList({
    required this.title,
    required this.color,
    required this.background,
    required this.items,
  });

  final String title;
  final Color color;
  final Color background;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 5, color: color.withValues(alpha: 0.7)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: color.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
