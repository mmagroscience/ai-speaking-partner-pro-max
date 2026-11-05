import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/kids_catalog.dart';
import '../../services/tts_service.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

class KidsLessonScreen extends StatefulWidget {
  const KidsLessonScreen({super.key, required this.week});

  final KidsWeek week;

  @override
  State<KidsLessonScreen> createState() => _KidsLessonScreenState();
}

class _KidsLessonScreenState extends State<KidsLessonScreen> {
  final PageController _controller = PageController();
  final TtsService _tts = TtsService();
  final Set<int> _said = {};

  int _index = 0;
  int _stars = 0;
  bool _finished = false;

  KidsWeek get _week => widget.week;

  @override
  void dispose() {
    _controller.dispose();
    _tts.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final stars = _said.length >= _week.wordCount ? 3 : 2;
    await context.read<AppState>().completeKidsWeek(_week.number, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _finished = true;
    });
  }

  void _restart() {
    setState(() {
      _finished = false;
      _index = 0;
      _stars = 0;
      _said.clear();
    });
    if (_controller.hasClients) _controller.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult(context);

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HeaderBar(
              title: 'Week ${_week.number} · ${_week.title}',
              subtitle: _week.banglaTitle,
              onBack: () => Navigator.pop(context),
              trailing: Pill(
                label: '${_week.cardCount} cards',
                color: _week.colors.last,
                background: _week.colors.first.withValues(alpha: 0.14),
                fontSize: 9.5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Card ${_index + 1} of ${_week.cardCount}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '⭐ ${_said.length}/${_week.wordCount} said',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _week.cardCount,
                  minHeight: 6,
                  backgroundColor: AppColors.pale,
                  valueColor: AlwaysStoppedAnimation(_week.colors.last),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _week.cardCount,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  if (index < _week.words.length) {
                    final word = _week.words[index];
                    return _WordCard(
                      word: word,
                      said: _said.contains(index),
                      onListen: () => _tts.speak('${word.word}. ${word.sentence}'),
                      onToggle: () {
                        setState(() {
                          if (_said.contains(index)) {
                            _said.remove(index);
                          } else {
                            _said.add(index);
                          }
                        });
                      },
                    );
                  }
                  final phrase = _week.phrases[index - _week.words.length];
                  return _PhraseCard(
                    phrase: phrase,
                    onListen: () => _tts.speak(phrase.text),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                children: [
                  if (_index > 0) ...[
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(15),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 20, color: AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: GradientButton(
                      label: _index == _week.cardCount - 1
                          ? 'Finish lesson'
                          : 'Next card',
                      icon: _index == _week.cardCount - 1
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      gradient: LinearGradient(colors: _week.colors),
                      onPressed: () {
                        if (_index == _week.cardCount - 1) {
                          _finish();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'পাশে বসে স্পিকার চাপুন — শিশু শুনে শুনে বলবে।',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9.5,
                      color: AppColors.muted.withValues(alpha: 0.75),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _week.colors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _week.colors.last.withValues(alpha: 0.32),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                'Week ${_week.number} complete!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _week.banglaTitle,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      index < _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 46,
                      color: index < _stars ? AppColors.amber : AppColors.line,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text(
                _stars == 3
                    ? 'Superstar! Every word was said out loud.'
                    : 'Great job! Say every word next time for 3 stars.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _ResultStat(
                      emoji: '🧸',
                      value: '${_week.words.length}',
                      label: 'words',
                    ),
                    Container(
                        width: 1, height: 34, color: AppColors.line),
                    _ResultStat(
                      emoji: '💬',
                      value: '${_week.phrases.length}',
                      label: 'sentences',
                    ),
                    Container(
                        width: 1, height: 34, color: AppColors.line),
                    _ResultStat(
                      emoji: '⏱️',
                      value: '10',
                      label: 'minutes',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _week.parentTip,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GradientButton(
                label: 'Practice again',
                icon: Icons.replay_rounded,
                height: 52,
                onPressed: _restart,
              ),
              const SizedBox(height: 9),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.said,
    required this.onListen,
    required this.onToggle,
  });

  final KidsWord word;
  final bool said;
  final VoidCallback onListen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 12),
          child: Center(
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppColors.pale,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Center(
                      child: Text(
                        word.emoji,
                        style: const TextStyle(fontSize: 58, height: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    word.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    word.bangla,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.pale.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      word.sentence,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purple,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onListen,
                          icon: const Icon(Icons.volume_up_rounded, size: 19),
                          label: const Text('Listen'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onToggle,
                          icon: Icon(
                            said
                                ? Icons.check_circle_rounded
                                : Icons.record_voice_over_rounded,
                            size: 19,
                          ),
                          label: Text(said ? 'Said!' : 'I said it'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor:
                                said ? AppColors.mintDeep : AppColors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({required this.phrase, required this.onListen});

  final KidsPhrase phrase;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 12),
          child: Center(
            child: GlassCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text('💬', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SAY THIS TOGETHER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    phrase.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phrase.bangla,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onListen,
                    icon: const Icon(Icons.volume_up_rounded, size: 19),
                    label: const Text('Listen and repeat'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
