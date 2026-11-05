import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../services/tts_service.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final TtsService _tts = TtsService();
  VocabTone _tone = VocabTone.casual;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final words = Catalog.vocabulary.where((word) {
      if (word.tone != _tone) return false;
      if (_query.isEmpty) return true;
      final query = _query.toLowerCase();
      return word.word.toLowerCase().contains(query) ||
          word.meaningBn.contains(query) ||
          word.meaningEn.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HeaderBar(
                title: '3-Tone Vocabulary',
                subtitle: 'Casual, business formal & native idioms',
                onBack: () => Navigator.pop(context),
                trailing: IconButton(
                  onPressed: () => _openQuiz(context),
                  icon: const Icon(Icons.quiz_outlined),
                  tooltip: 'Quiz me',
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Row(
                          children: VocabTone.values.map((tone) {
                            final selected = _tone == tone;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _tone = tone),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.purple
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        tone.icon,
                                        size: 16,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.muted,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        tone.shortLabel,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => setState(() => _query = value.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Search a word or Bangla meaning…',
                          prefixIcon: Icon(Icons.search_rounded, size: 19),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            '${words.length} words',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _openQuiz(context),
                            icon: const Icon(Icons.play_arrow_rounded, size: 16),
                            label: const Text('Quiz me'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (words.isEmpty)
                        const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Nothing found',
                          message: 'Try a different word or switch tones.',
                        )
                      else
                        ...words.map(
                          (word) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _VocabCard(
                              word: word,
                              favorite: state.isFavorite(word.id),
                              onFavorite: () => state.toggleFavorite(word.id),
                              onSpeak: () => _tts.speak(word.word),
                              onTap: () => _openDetail(context, state, word),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.pale.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                size: 18, color: AppColors.purple),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'After every call, your last sentence is rewritten in all three tones. That is how you learn to switch registers naturally.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.purple,
                                  height: 1.45,
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
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, AppState state, VocabWord word) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pill(
                  label: word.tone.shortLabel,
                  icon: word.tone.icon,
                  color: AppColors.purple,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => state.toggleFavorite(word.id),
                  icon: Icon(
                    state.isFavorite(word.id)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              word.phonetic,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.violet,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Meaning (বাংলা)', value: word.meaningBn),
            _DetailRow(label: 'In English', value: word.meaningEn),
            _DetailRow(label: 'Example', value: word.example, highlight: true),
            if (word.tip.isNotEmpty)
              _DetailRow(label: 'Coach tip', value: word.tip),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Hear pronunciation',
                icon: Icons.volume_up_rounded,
                onPressed: () => _tts.speak(word.word),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openQuiz(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _QuizSheet(),
    );
  }
}

class _VocabCard extends StatelessWidget {
  const _VocabCard({
    required this.word,
    required this.favorite,
    required this.onFavorite,
    required this.onSpeak,
    required this.onTap,
  });

  final VocabWord word;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onSpeak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: switch (word.tone) {
                VocabTone.casual => AppColors.mintSoft,
                VocabTone.formal => AppColors.pale,
                VocabTone.idiomatic => AppColors.amberSoft,
              },
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              word.tone.icon,
              size: 20,
              color: switch (word.tone) {
                VocabTone.casual => AppColors.mintDeep,
                VocabTone.formal => AppColors.purple,
                VocabTone.idiomatic => const Color(0xFFB45309),
              },
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        word.word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      word.phonetic,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.lavender,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  word.meaningBn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    fontFamily: 'HindSiliguri',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  word.example,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onFavorite,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: favorite ? AppColors.amber : AppColors.line,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onSpeak,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.volume_up_outlined,
                    size: 18,
                    color: AppColors.purple,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.mintSoft.withValues(alpha: 0.5) : AppColors.bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: highlight ? AppColors.mintDeep : AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: highlight ? AppColors.mintDeep : AppColors.ink,
              fontFamily: label.contains('বাংলা') ? 'HindSiliguri' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizSheet extends StatefulWidget {
  const _QuizSheet();

  @override
  State<_QuizSheet> createState() => _QuizSheetState();
}

class _QuizSheetState extends State<_QuizSheet> {
  late final List<VocabWord> _questions;
  late final Map<String, List<String>> _options;
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final all = List<VocabWord>.of(Catalog.vocabulary)..shuffle(math.Random(7));
    _questions = all.take(6).toList();
    _options = {};
    for (final word in _questions) {
      final others = all
          .where((w) => w.id != word.id)
          .map((w) => w.meaningBn)
          .toSet()
          .toList()
        ..shuffle(math.Random(word.word.hashCode));
      _options[word.id] = [word.meaningBn, ...others.take(3)]..shuffle(
          math.Random(word.word.length + word.tone.index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
      child: _finished ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final word = _questions[_index];
    final options = _options[word.id]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quiz • ${_index + 1}/${_questions.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const Spacer(),
            Pill(
              label: '$_score correct',
              color: AppColors.mintDeep,
              background: AppColors.mintSoft,
              fontSize: 8.5,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          word.word,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        Text(
          word.phonetic,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.violet,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 6),
        Text('What does this word mean?',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        ...List.generate(options.length, (index) {
          final option = options[index];
          final isCorrect = option == word.meaningBn;
          final selected = _selected == index;
          final reveal = _selected != null;
          final color = !reveal
              ? AppColors.line
              : isCorrect
                  ? AppColors.mint
                  : selected
                      ? AppColors.rose
                      : AppColors.line;
          final background = !reveal
              ? AppColors.bg
              : isCorrect
                  ? AppColors.mintSoft
                  : selected
                      ? AppColors.roseSoft
                      : AppColors.bg;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _selected == null
                  ? () => setState(() {
                        _selected = index;
                        if (isCorrect) _score++;
                      })
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color),
                ),
                child: Row(
                  children: [
                    Icon(
                      reveal
                          ? (isCorrect
                              ? Icons.check_circle_rounded
                              : selected
                                  ? Icons.cancel_rounded
                                  : Icons.circle_outlined)
                          : Icons.circle_outlined,
                      size: 17,
                      color: reveal
                          ? (isCorrect
                              ? AppColors.mintDeep
                              : selected
                                  ? AppColors.rose
                                  : AppColors.muted)
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'HindSiliguri',
                          color: AppColors.ink,
                          fontWeight: isCorrect && reveal
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        GradientButton(
          label: _index == _questions.length - 1 ? 'See my score' : 'Next word',
          icon: Icons.arrow_forward_rounded,
          onPressed: _selected == null
              ? null
              : () {
                  if (_index == _questions.length - 1) {
                    setState(() => _finished = true);
                  } else {
                    setState(() {
                      _index++;
                      _selected = null;
                    });
                  }
                },
        ),
      ],
    );
  }

  Widget _buildResult() {
    final percent = (_score / _questions.length * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        ScoreRing(
          value: _score / _questions.length,
          size: 120,
          label: 'score',
          color: percent >= 70 ? AppColors.mint : AppColors.amber,
        ),
        const SizedBox(height: 12),
        Text(
          percent >= 70 ? 'Strong recall!' : 'Good start — keep going.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 5),
        Text(
          'You got $_score out of ${_questions.length} correct.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: 'Finish',
          icon: Icons.check_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
