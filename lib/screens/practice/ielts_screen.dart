import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../services/ielts_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

enum _Stage { intro, test, result }

class IeltsScreen extends StatefulWidget {
  const IeltsScreen({super.key});

  @override
  State<IeltsScreen> createState() => _IeltsScreenState();
}

class _IeltsScreenState extends State<IeltsScreen> {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();
  late final List<_IeltsStep> _steps;
  late final List<String> _answers;
  late final List<int> _stepSeconds;

  _Stage _stage = _Stage.intro;
  int _index = 0;
  int _prepRemaining = 0;
  int _remaining = 0;
  int _elapsed = 0;
  bool _prepActive = false;
  bool _listening = false;
  String _partial = '';
  Timer? _prepTimer;
  Timer? _speakTimer;
  BandResult? _result;

  @override
  void initState() {
    super.initState();
    _tts.init();
    final cue = Catalog.ieltsCueCards[
        DateTime.now().day % Catalog.ieltsCueCards.length];
    _steps = [
      for (var i = 0; i < 3; i++)
        _IeltsStep(
          part: 'Part 1',
          prompt: Catalog.ieltsPart1[i],
          limitSeconds: 45,
        ),
      _IeltsStep(
        part: 'Part 2',
        prompt: cue.topic,
        bullets: cue.points,
        prepSeconds: 60,
        limitSeconds: 120,
      ),
      for (var i = 0; i < 2; i++)
        _IeltsStep(
          part: 'Part 3',
          prompt: Catalog.ieltsPart3[i],
          limitSeconds: 60,
        ),
    ];
    _answers = List<String>.filled(_steps.length, '');
    _stepSeconds = List<int>.filled(_steps.length, 0);
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _speakTimer?.cancel();
    _speech.dispose();
    _tts.dispose();
    super.dispose();
  }

  _IeltsStep get _step => _steps[_index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HeaderBar(
                title: 'IELTS Speaking',
                subtitle: _stage == _Stage.intro
                    ? 'Official-style mock test'
                    : _stage == _Stage.test
                        ? '${_step.part} • ${_index + 1} of ${_steps.length}'
                        : 'Estimated band score',
                onBack: _handleBack,
                trailing: _stage == _Stage.test
                    ? Pill(
                        label: 'LIVE',
                        color: AppColors.rose,
                        background: AppColors.roseSoft,
                        fontSize: 8,
                      )
                    : null,
              ),
              Expanded(
                child: switch (_stage) {
                  _Stage.intro => _buildIntro(),
                  _Stage.test => _buildTest(),
                  _Stage.result => _buildResult(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.24),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Colors.white, size: 29),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Full speaking mock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Three parts, six questions, one honest band estimate.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final part in const [
                      'Part 1\nIntro',
                      'Part 2\nCue card',
                      'Part 3\nDiscussion',
                    ])
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            part,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'How it works',
            subtitle: 'Same rhythm as the real exam',
          ),
          const _InfoStep(
            number: '1',
            title: 'Part 1 — Introduction',
            message:
                'Three everyday questions, 45 seconds each. Answer directly, then add a reason.',
          ),
          const _InfoStep(
            number: '2',
            title: 'Part 2 — Cue card',
            message:
                'One minute to prepare, then speak for up to two minutes about the topic.',
          ),
          const _InfoStep(
            number: '3',
            title: 'Part 3 — Discussion',
            message:
                'Two abstract follow-up questions, 60 seconds each. Give an opinion and an example.',
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mintSoft.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mic_rounded, size: 18, color: AppColors.mintDeep),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Speak out loud, or tap “Type answer” if a microphone is not available on this device.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.45,
                      color: AppColors.mintDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Start full mock test',
            icon: Icons.play_arrow_rounded,
            onPressed: _startTest,
          ),
        ],
      ),
    );
  }

  Widget _buildTest() {
    final step = _step;
    final progress = _index / _steps.length;
    final answer = _answers[_index];
    final showPrep = _prepActive;
    final timerValue = showPrep ? _prepRemaining : _remaining;
    final timerTotal =
        showPrep ? step.prepSeconds : step.limitSeconds;
    final timerColor = showPrep
        ? AppColors.amber
        : (_remaining <= 10 ? AppColors.rose : AppColors.mint);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.pale,
              valueColor: const AlwaysStoppedAnimation(AppColors.purple),
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(
                      label: step.part.toUpperCase(),
                      color: AppColors.purple,
                      fontSize: 8.5,
                    ),
                    const SizedBox(width: 6),
                    if (showPrep)
                      Pill(
                        label: 'PREPARATION',
                        color: const Color(0xFFB45309),
                        background: AppColors.amberSoft,
                        fontSize: 8,
                      )
                    else
                      Pill(
                        label: 'SPEAK NOW',
                        color: AppColors.mintDeep,
                        background: AppColors.mintSoft,
                        fontSize: 8,
                      ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _listening ? null : _listenToQuestion,
                      icon: const Icon(Icons.volume_up_outlined, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  step.prompt,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.35,
                    letterSpacing: -0.2,
                  ),
                ),
                if (step.bullets.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...step.bullets.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ',
                              style: TextStyle(color: AppColors.lavender)),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: timerTotal == 0
                            ? 0
                            : timerValue / timerTotal,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.pale,
                        valueColor: AlwaysStoppedAnimation(timerColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${timerValue}s',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1,
                          ),
                        ),
                        Text(
                          showPrep ? 'prep' : 'left',
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showPrep
                          ? 'Make a few notes. You can start early.'
                          : _listening
                              ? 'Recording… speak clearly.'
                              : 'Tap the mic when you are ready.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      showPrep
                          ? 'The examiner will ask you to speak after the timer.'
                          : 'Aim for 3–5 connected sentences, not one word.',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (showPrep)
            Column(
              children: [
                Text(
                  'Preparation time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Read the cue card and plan your four bullet points.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'Start speaking now',
                  icon: Icons.mic_rounded,
                  onPressed: _skipPrep,
                ),
                TextButton(
                  onPressed: _skipPrep,
                  child: const Text('Skip preparation'),
                ),
              ],
            )
          else if (!_listening)
            Column(
              children: [
                GradientButton(
                  label: answer.isEmpty ? 'Start speaking' : 'Record again',
                  icon: Icons.mic_rounded,
                  onPressed: _startSpeaking,
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _typeAnswer,
                  icon: const Icon(Icons.keyboard_rounded, size: 16),
                  label: const Text('Type answer'),
                ),
              ],
            )
          else
            _RecordingPanel(
              partial: _partial,
              onStop: () => _finishAnswer(auto: false),
            ),
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintSoft.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Saved answer: “${answer.length > 160 ? '${answer.substring(0, 160)}…' : answer}”',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mintDeep,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResult() {
    final result = _result!;
    final band = result.overall;
    final bandColor = band >= 7
        ? AppColors.mint
        : band >= 6
            ? AppColors.violet
            : AppColors.amber;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      child: Column(
        children: [
          const SizedBox(height: 6),
          ScoreRing(
            value: band / 9,
            size: 142,
            stroke: 10,
            label: 'band',
            color: bandColor,
            displayText: band.toStringAsFixed(1),
          ),
          const SizedBox(height: 10),
          Text(
            _bandHeadline(band),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated from fluency, vocabulary, grammar and pronunciation signals.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultStat(
                    value: '${result.words}', label: 'words'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultStat(value: '${result.wpm}', label: 'words/min'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultStat(
                    value: '${result.fillers}', label: 'fillers'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...result.criteria.entries.map((entry) {
            final value = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: value >= 6.5
                              ? AppColors.mintDeep
                              : AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: value / 9,
                      minHeight: 5,
                      backgroundColor: AppColors.pale,
                      valueColor: AlwaysStoppedAnimation(
                        value >= 6.5 ? AppColors.mint : AppColors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.feedback[entry.key] ?? '',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.pale.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    size: 18, color: AppColors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a practice estimate, not an official IELTS result. A real examiner also considers eye contact, hesitation and overall communicative effectiveness.',
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.45,
                      color: AppColors.purple.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Try again'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _bandHeadline(double band) {
    if (band >= 7.5) return 'That is a strong band. Keep the momentum!';
    if (band >= 6.5) return 'You are close to a competitive band.';
    if (band >= 5.5) return 'A solid base — now build longer answers.';
    return 'A good first attempt. Let\'s make the next one longer.';
  }

  void _startTest() {
    setState(() {
      _stage = _Stage.test;
      _index = 0;
      _answers.fillRange(0, _answers.length, '');
      _stepSeconds.fillRange(0, _stepSeconds.length, 0);
    });
    _enterStep();
  }

  void _enterStep() {
    _prepTimer?.cancel();
    _speakTimer?.cancel();
    final step = _step;
    setState(() {
      _prepRemaining = step.prepSeconds;
      _remaining = step.limitSeconds;
      _elapsed = 0;
      _partial = '';
      _listening = false;
      _prepActive = step.prepSeconds > 0;
    });
    if (step.prepSeconds > 0) {
      _prepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_prepRemaining <= 1) {
          timer.cancel();
          setState(() {
            _prepRemaining = 0;
            _prepActive = false;
          });
        } else {
          setState(() => _prepRemaining--);
        }
      });
    }
  }

  void _skipPrep() {
    _prepTimer?.cancel();
    setState(() {
      _prepActive = false;
      _prepRemaining = 0;
    });
  }

  Future<void> _startSpeaking() async {
    await _tts.stop();
    setState(() {
      _listening = true;
      _partial = '';
      _elapsed = 0;
      _remaining = _step.limitSeconds;
    });
    _speech
        .listen(
      localeId: 'en_US',
      listenFor: Duration(seconds: _step.limitSeconds),
      pauseFor: const Duration(seconds: 4),
      onPartial: (value) {
        if (mounted) setState(() => _partial = value);
      },
    )
        .then((value) {
      if (!mounted) return;
      if (value != null && value.trim().isNotEmpty) {
        setState(() => _partial = value.trim());
      }
      if (_listening) setState(() => _listening = false);
    });
    _speakTimer?.cancel();
    _speakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsed++;
        _remaining = (_step.limitSeconds - _elapsed).clamp(0, _step.limitSeconds);
      });
      if (_remaining <= 0) {
        timer.cancel();
        _finishAnswer(auto: true);
      }
    });
  }

  Future<void> _finishAnswer({required bool auto}) async {
    _speakTimer?.cancel();
    await _speech.stop();
    if (!mounted) return;
    final text = _partial.trim();
    setState(() {
      _listening = false;
      _remaining = 0;
    });
    if (text.isEmpty) {
      if (!auto) {
        AppUtils.showSnack(
          context,
          'No speech detected. Try again or tap “Type answer”.',
          error: true,
        );
        setState(() => _remaining = _step.limitSeconds);
      }
      return;
    }
    _answers[_index] = text;
    _stepSeconds[_index] = _elapsed < 1 ? 1 : _elapsed;
    if (_index >= _steps.length - 1) {
      _computeResult();
    } else {
      setState(() => _index++);
      _enterStep();
    }
  }

  Future<void> _typeAnswer() async {
    final controller = TextEditingController(text: _answers[_index]);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_step.part == 'Part 2' ? 'Type your talk' : 'Type your answer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Write what you would say…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save answer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    _answers[_index] = value.trim();
    _stepSeconds[_index] = (_step.limitSeconds * 0.6).round();
    if (_index >= _steps.length - 1) {
      _computeResult();
    } else {
      setState(() => _index++);
      _enterStep();
    }
  }

  void _computeResult() {
    final totalSeconds = _stepSeconds.fold<int>(0, (sum, value) => sum + value);
    final fillers = _answers
        .fold<int>(0, (sum, answer) => sum + AppUtils.countFillers(answer));
    final result = IeltsService.estimate(
      answers: _answers.where((answer) => answer.isNotEmpty).toList(),
      seconds: totalSeconds,
      fillers: fillers,
    );
    setState(() {
      _result = result;
      _stage = _Stage.result;
    });
  }

  Future<void> _listenToQuestion() async {
    await _tts.speak(_step.prompt);
  }

  void _reset() {
    _prepTimer?.cancel();
    _speakTimer?.cancel();
    setState(() {
      _stage = _Stage.intro;
      _index = 0;
      _answers.fillRange(0, _answers.length, '');
      _stepSeconds.fillRange(0, _stepSeconds.length, 0);
      _partial = '';
      _listening = false;
      _result = null;
    });
  }

  Future<void> _handleBack() async {
    if (_stage != _Stage.test) {
      Navigator.pop(context);
      return;
    }
    final ok = await AppUtils.confirm(
      context,
      title: 'Leave the mock test?',
      message: 'Your answers for this attempt will be lost.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (!ok) return;
    await _speech.stop();
    await _tts.stop();
    if (mounted) Navigator.pop(context);
  }
}

class _IeltsStep {
  const _IeltsStep({
    required this.part,
    required this.prompt,
    this.bullets = const [],
    this.prepSeconds = 0,
    required this.limitSeconds,
  });

  final String part;
  final String prompt;
  final List<String> bullets;
  final int prepSeconds;
  final int limitSeconds;
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({
    required this.number,
    required this.title,
    required this.message,
  });

  final String number;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.pale,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.muted,
                    height: 1.45,
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

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({required this.partial, required this.onStop});

  final String partial;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          const _PulseDot(),
          const SizedBox(height: 8),
          const Text(
            'Listening…',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if (partial.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '“$partial”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: onStop,
            icon: const Icon(Icons.stop_rounded, size: 18),
            label: const Text('Stop & save'),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: 34 + _controller.value * 10,
        height: 34 + _controller.value * 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.rose.withValues(alpha: 0.12),
        ),
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.rose,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 13),
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
