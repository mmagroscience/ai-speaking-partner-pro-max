import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../services/pronunciation_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key});

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();
  int _index = 0;
  bool _listening = false;
  String _partial = '';
  PronunciationResult? _result;
  String? _transcript;

  Phrase get _phrase => Catalog.phrases[_index];

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _speech.dispose();
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HeaderBar(
                title: 'Pronunciation Lab',
                subtitle: 'Green is clear. Amber needs another try.',
                onBack: () => Navigator.pop(context),
                trailing: Pill(
                  label: '${_index + 1}/${Catalog.phrases.length}',
                  color: AppColors.purple,
                  fontSize: 9,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: Catalog.phrases.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final selected = index == _index;
                            return Material(
                              color: selected
                                  ? AppColors.purple
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setState(() {
                                  _index = index;
                                  _result = null;
                                  _transcript = null;
                                  _partial = '';
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.purple
                                          : AppColors.line,
                                    ),
                                  ),
                                  child: Text(
                                    Catalog.phrases[index].focus,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ScoreRing(
                          value: (_result?.score ?? 0) / 100,
                          size: 118,
                          stroke: 9,
                          label: _result == null ? 'ready' : 'score',
                          color: (_result?.score ?? 0) >= 80
                              ? AppColors.mint
                              : AppColors.violet,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Pill(
                                  label: _phrase.focus,
                                  icon: Icons.graphic_eq_rounded,
                                  color: AppColors.purple,
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _listen,
                                  icon:
                                      const Icon(Icons.volume_up_rounded, size: 16),
                                  label: const Text('Listen'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _phrase.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                                height: 1.35,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _phrase.ipa,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.violet,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.mintSoft.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.translate_rounded,
                                      size: 16, color: AppColors.mintDeep),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      _phrase.banglaTip,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.mintDeep,
                                        height: 1.5,
                                        fontFamily: 'HindSiliguri',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_result == null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _listening
                                    ? Icons.graphic_eq_rounded
                                    : Icons.mic_none_rounded,
                                size: 38,
                                color: _listening
                                    ? AppColors.rose
                                    : AppColors.purple,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _listening
                                    ? 'Listening… speak naturally'
                                    : 'Tap the mic and say the sentence',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (_partial.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  '“$_partial”',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _MicButton(
                                listening: _listening,
                                onTap: _toggleListening,
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _typeTranscript,
                                icon: const Icon(Icons.keyboard_rounded,
                                    size: 15),
                                label: const Text('Type instead'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        _ResultCard(
                          result: _result!,
                          transcript: _transcript ?? '',
                          onRetry: _toggleListening,
                          listening: _listening,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _demo,
                                child: const Text('Demo score'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _index =
                                        (_index + 1) % Catalog.phrases.length;
                                    _result = null;
                                    _transcript = null;
                                  });
                                },
                                child: const Text('Next phrase'),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Future<void> _listen() async {
    await _tts.speak(_phrase.text);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    await _tts.stop();
    setState(() {
      _listening = true;
      _partial = '';
      _result = null;
      _transcript = null;
    });
    final text = await _speech.listen(
      localeId: 'en_US',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 2),
      onPartial: (value) {
        if (mounted) setState(() => _partial = value);
      },
    );
    if (!mounted) return;
    setState(() => _listening = false);
    if (text == null || text.trim().isEmpty) {
      AppUtils.showSnack(
        context,
        'I could not hear a full sentence. Try again, or type what you said.',
        error: true,
      );
      return;
    }
    _evaluate(text);
  }

  void _evaluate(String transcript) {
    final result = PronunciationService.evaluate(_phrase, transcript);
    setState(() {
      _result = result;
      _transcript = transcript;
      _partial = '';
    });
    context.read<AppState>().recordPronunciationScore(result.score);
  }

  Future<void> _typeTranscript() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What did you say?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type your sentence…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Check'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    _evaluate(value.trim());
  }

  void _demo() {
    final result = PronunciationService.demo(_phrase);
    setState(() {
      _result = result;
      _transcript = _phrase.text;
    });
    context.read<AppState>().recordPronunciationScore(result.score);
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onTap});

  final bool listening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, _) => Material(
        color: listening ? AppColors.rose : AppColors.purple,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (listening ? AppColors.rose : AppColors.purple)
                      .withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              listening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.transcript,
    required this.onRetry,
    required this.listening,
  });

  final PronunciationResult result;
  final String transcript;
  final VoidCallback onRetry;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final feedback = PronunciationService.feedback(result);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Word by word',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Pill(
                label: '${result.perfectCount} clear',
                color: AppColors.mintDeep,
                background: AppColors.mintSoft,
                fontSize: 8.5,
              ),
              const SizedBox(width: 4),
              Pill(
                label: '${result.closeCount} close',
                color: const Color(0xFFB45309),
                background: AppColors.amberSoft,
                fontSize: 8.5,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: result.words
                .map(
                  (word) => _WordChip(
                    word: word,
                    color: switch (word.status) {
                      WordStatus.perfect => AppColors.mintDeep,
                      WordStatus.close => const Color(0xFFB45309),
                      WordStatus.missed => AppColors.rose,
                    },
                    background: switch (word.status) {
                      WordStatus.perfect => AppColors.mintSoft,
                      WordStatus.close => AppColors.amberSoft,
                      WordStatus.missed => AppColors.roseSoft,
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'You said: “$transcript”',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.pale.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              feedback,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.purple,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(
                listening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 17,
              ),
              label: Text(listening ? 'Stop' : 'Try again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.word,
    required this.color,
    required this.background,
  });

  final WordScore word;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (word.status) {
              WordStatus.perfect => Icons.check_rounded,
              WordStatus.close => Icons.change_circle_outlined,
              WordStatus.missed => Icons.close_rounded,
            },
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            word.spokenAs.isEmpty
                ? word.word
                : '${word.word} → ${word.spokenAs}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
