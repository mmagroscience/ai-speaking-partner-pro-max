import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/flashcard_models.dart';
import '../../services/flashcard_service.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import 'flashcard_study_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late final Future<List<Flashcard>> _future = FlashcardService.load();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final level = state.studyLevel;

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Flashcard>>(
          future: _future,
          builder: (context, snapshot) {
            final all = snapshot.data;
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderBar(
                    title: 'Flashcards',
                    subtitle: all == null
                        ? 'Oxford 3000 • Baby → University'
                        : '${all.length} cards • Baby → University',
                    trailing: Pill(
                      label: '${state.flashKnown.length} known',
                      color: AppColors.mintDeep,
                      background: AppColors.mintSoft,
                      fontSize: 9.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LevelHero(
                          level: level,
                          known: state.flashKnown.length,
                          studied: state.flashSeen.length,
                          decks: state.flashDecks,
                          count: all == null
                              ? null
                              : FlashcardService.countFor(all, level),
                          onStart: () => _openStudy(context, level),
                          onChange: () => _pickLevel(context, state),
                        ),
                        const SizedBox(height: 20),
                        const SectionHeader(
                          title: 'Choose your level',
                          subtitle: 'Baby, Class 1–12 and University',
                        ),
                        if (all == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.purple,
                              ),
                            ),
                          )
                        else
                          _LevelGrid(
                            all: all,
                            selected: level,
                            onSelect: (value) {
                              state.setStudyLevel(value);
                              _openStudy(context, value);
                            },
                          ),
                        const SizedBox(height: 16),
                        GlassCard(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.amberSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFFB45309),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Oxford 3000, ready offline',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'IPA, part of speech, CEFR level, definitions '
                                      'and real examples. Tap a card to flip, '
                                      'swipe right when you know it.',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        height: 1.45,
                                        color: AppColors.muted.withValues(
                                          alpha: 0.95,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'সব কার্ড অফলাইনে কাজ করে — ইন্টারনেট লাগবে না।',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: AppColors.muted.withValues(alpha: 0.8),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openStudy(BuildContext context, StudyLevel level) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FlashcardStudyScreen(level: level)),
    );
  }

  void _pickLevel(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LevelSheet(selected: state.studyLevel),
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({
    required this.level,
    required this.known,
    required this.studied,
    required this.decks,
    required this.count,
    required this.onStart,
    required this.onChange,
  });

  final StudyLevel level;
  final int known;
  final int studied;
  final int decks;
  final int? count;
  final VoidCallback onStart;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF241040),
            level.colors.last.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: level.colors.last.withValues(alpha: 0.3),
            blurRadius: 26,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'OXFORD 3000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(level.emoji, style: const TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            level.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${level.bnLabel} • ${level.stage}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.wordHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroStat(value: '$known', label: 'known'),
              _HeroStat(value: '$studied', label: 'studied'),
              _HeroStat(value: '$decks', label: 'decks'),
              _HeroStat(value: count == null ? '—' : '$count', label: 'cards'),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onStart,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.deep,
                            size: 20,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Start studying',
                            style: TextStyle(
                              color: AppColors.deep,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Material(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onChange,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 19,
                    ),
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelGrid extends StatelessWidget {
  const _LevelGrid({
    required this.all,
    required this.selected,
    required this.onSelect,
  });

  final List<Flashcard> all;
  final StudyLevel selected;
  final ValueChanged<StudyLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: StudyLevel.values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (context, index) {
        final level = StudyLevel.values[index];
        final isSelected = level == selected;
        final count = FlashcardService.countFor(all, level);
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => onSelect(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.pale
                    : Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: isSelected
                      ? level.colors.last.withValues(alpha: 0.55)
                      : Colors.white,
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: level.colors),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Text(
                        level.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$count cards',
                          style: const TextStyle(
                            fontSize: 9,
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
      },
    );
  }
}

class _LevelSheet extends StatelessWidget {
  const _LevelSheet({required this.selected});

  final StudyLevel selected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pick a level',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Baby থেকে University — যেকোনো সময় বদলাতে পারবেন।',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            ...StudyLevel.values.map((level) {
              final isSelected = level == selected;
              final isCurrent = level == state.studyLevel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Material(
                  color: isSelected ? AppColors.pale : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      state.setStudyLevel(level);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: level.colors),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Text(
                                level.emoji,
                                style: const TextStyle(fontSize: 17),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  '${level.bnLabel} • ${level.wordHint}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 19,
                              color: AppColors.mintDeep,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
