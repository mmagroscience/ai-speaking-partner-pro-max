import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/talking_avatar.dart';
import '../../widgets/waveform.dart';

/// The face-to-face video call with an AI partner.
///
/// The AI speaks first, then the learner answers by voice (or by typing when a
/// microphone is not available). Every AI turn drives the avatar, the live
/// subtitles and the end-of-call report.
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.scenario,
    required this.persona,
  });

  final Scenario scenario;
  final Persona persona;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with WidgetsBindingObserver {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();
  final TextEditingController _textController = TextEditingController();

  late final AppState _state;

  List<ChatTurn> _history = [];
  AiReply? _lastReply;
  String _lastAiText = '';
  String _partial = '';
  String _status = 'Connecting…';

  Timer? _ticker;
  Timer? _speakGuard;
  int _elapsed = 0;
  int _runId = 0;

  bool _starting = true;
  bool _aiSpeaking = false;
  bool _listening = false;
  bool _thinking = false;
  bool _micMuted = false;
  bool _cameraOn = true;
  bool _speakerOn = true;
  bool _captionsOn = true;
  bool _autoListen = false;
  bool _ending = false;
  bool _ended = false;
  bool _showTypeFallback = false;
  int _emptyListens = 0;

  int _userTurns = 0;
  int _wordTotal = 0;
  int _fillerTotal = 0;

  bool get _hasCoachTip {
    final reply = _lastReply;
    if (reply == null) return false;
    return reply.correction.trim().isNotEmpty ||
        reply.betterWay.trim().isNotEmpty ||
        reply.banglaTip.trim().isNotEmpty;
  }

  String get _sourceLabel {
    if (!_state.ai.hasKeys) return 'Offline coach';
    if (_lastReply == null) return 'Gemini ready';
    return _state.ai.lastSource;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = context.read<AppState>();
    _speakerOn = _state.autoSpeak;
    _tts.onStart = () {
      if (mounted && !_ended) setState(() => _aiSpeaking = true);
    };
    _tts.onComplete = () {
      if (!mounted || _ended) return;
      setState(() => _aiSpeaking = false);
      _afterAiSpeaks();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runId++;
    _ticker?.cancel();
    _speakGuard?.cancel();
    _speech.dispose();
    _tts.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ended) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Stop audio and the recognizer so a backgrounded call does not keep
      // the microphone hot or talk over another app.
      _autoListen = false;
      _speakGuard?.cancel();
      unawaited(_speech.cancel());
      unawaited(_tts.stop());
      if (!mounted) return;
      setState(() {
        _listening = false;
        _aiSpeaking = false;
        _partial = '';
        _status = 'Call paused';
      });
    } else if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _status = _listening ? 'Listening…' : 'Tap the mic to continue';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Conversation flow
  // ---------------------------------------------------------------------------

  Future<void> _begin() async {
    final token = ++_runId;
    if (mounted) {
      setState(() {
        _starting = true;
        _status = 'Connecting…';
      });
    }
    // Never let a slow or unavailable TTS engine block the call from starting.
    unawaited(_tts.init());
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _ended || token != _runId) return;

    final opening = widget.scenario.openingLine.trim().isEmpty
        ? widget.persona.greeting
        : widget.scenario.openingLine.trim();

    setState(() {
      _starting = false;
      _history = [ChatTurn(role: ChatRole.ai, text: opening)];
      _lastAiText = opening;
      _status = '${widget.persona.name} is speaking…';
    });
    _startTicker();
    await _speakAi(opening);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended) return;
      setState(() => _elapsed += 1);
      if (_elapsed >= kMaxCallMinutes * 60) {
        unawaited(_endCall());
      }
    });
  }

  Future<void> _speakAi(String text) async {
    if (_ended || !mounted) return;
    final words = math.max(4, text.trim().split(RegExp(r'\s+')).length);
    final readMs = (_speakerOn ? 1400 + words * 330 : 1000)
        .clamp(1500, 26000)
        .toInt();

    _autoListen = true;
    _speakGuard?.cancel();
    _speakGuard = Timer(Duration(milliseconds: readMs), _afterAiSpeaks);

    setState(() {
      _aiSpeaking = true;
      _status = '${widget.persona.name} is speaking…';
    });

    if (!_speakerOn) return;
    await _tts.speak(text);
  }

  void _afterAiSpeaks() {
    if (_ended || !mounted || !_autoListen) return;
    _autoListen = false;
    _speakGuard?.cancel();

    setState(() {
      _aiSpeaking = false;
      _status = _micMuted ? 'Mic muted — unmute to speak' : 'Your turn';
    });

    if (!_micMuted && !_thinking && !_listening) {
      unawaited(_startListening());
    }
  }

  Future<void> _startListening() async {
    if (_ended || !mounted || _listening || _thinking || _micMuted) return;
    if (_aiSpeaking) {
      await _cancelAiSpeech();
      if (!mounted || _ended) return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _listening = true;
      _partial = '';
      _status = 'Listening…';
    });

    String? heard;
    try {
      heard = await _speech.listen(
        listenFor: const Duration(seconds: 28),
        pauseFor: const Duration(seconds: 3),
        onPartial: (value) {
          if (mounted && !_ended) setState(() => _partial = value);
        },
      );
    } catch (_) {
      heard = null;
    }

    if (!mounted || _ended) return;
    setState(() {
      _listening = false;
      _partial = '';
    });

    if (heard != null && heard.trim().isNotEmpty) {
      _emptyListens = 0;
      if (_showTypeFallback) setState(() => _showTypeFallback = false);
      await _handleUserText(heard.trim());
      return;
    }

    _emptyListens += 1;
    setState(() {
      if (!_speech.isAvailable) {
        _status = 'Mic unavailable — type instead';
        _showTypeFallback = true;
      } else if (_emptyListens >= 2) {
        _status = 'Mic is not catching you — type instead';
        _showTypeFallback = true;
      } else {
        _status = 'Tap the mic and speak';
      }
    });
  }

  Future<void> _cancelAiSpeech() async {
    _autoListen = false;
    _speakGuard?.cancel();
    unawaited(_tts.stop());
    if (mounted && !_ended) setState(() => _aiSpeaking = false);
  }

  Future<void> _handleUserText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _ended || _thinking) return;

    _autoListen = false;
    _speakGuard?.cancel();
    unawaited(_tts.stop());
    if (!mounted || _ended) return;

    final prior = List<ChatTurn>.from(_history);
    final words = AppUtils.wordCount(clean);
    final fillers = AppUtils.countFillers(clean);

    setState(() {
      _history = [..._history, ChatTurn(role: ChatRole.user, text: clean)];
      _userTurns += 1;
      _wordTotal += words;
      _fillerTotal += fillers;
      _thinking = true;
      _aiSpeaking = false;
      _partial = '';
      _showTypeFallback = false;
      _emptyListens = 0;
      _status = '${widget.persona.name} is thinking…';
    });

    AiReply reply;
    try {
      reply = await _state.ai.reply(
        persona: widget.persona,
        scenario: widget.scenario,
        history: prior,
        userText: clean,
        level: _state.level,
        banglaMode: _state.helpLanguage == HelpLanguage.bangla,
      );
    } catch (_) {
      reply = const AiReply(
        reply:
            'Sorry, I missed that. Could you say it one more time, a little slower?',
        emotion: 'caring',
      );
    }

    if (!mounted || _ended) return;

    setState(() {
      _history = [
        ..._history,
        ChatTurn(role: ChatRole.ai, text: reply.reply, reply: reply),
      ];
      _lastReply = reply;
      _lastAiText = reply.reply;
      _thinking = false;
    });

    await _speakAi(reply.reply);
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  Future<void> _tapMic() async {
    HapticFeedback.lightImpact();
    if (_micMuted) {
      setState(() {
        _micMuted = false;
        _status = 'Your turn';
      });
      await _startListening();
      return;
    }

    if (_listening) {
      setState(() => _status = 'Finishing your sentence…');
      await _speech.stop();
      return;
    }

    if (_thinking) return;
    await _startListening();
  }

  Future<void> _toggleMute() async {
    HapticFeedback.selectionClick();
    if (_listening) {
      unawaited(_speech.cancel());
      setState(() {
        _listening = false;
        _partial = '';
      });
    }
    setState(() {
      _micMuted = !_micMuted;
      _status = _micMuted ? 'Mic muted' : 'Tap the mic to speak';
    });
  }

  Future<void> _toggleSpeaker() async {
    HapticFeedback.selectionClick();
    setState(() => _speakerOn = !_speakerOn);
    if (!_speakerOn && _aiSpeaking) {
      unawaited(_tts.stop());
      _afterAiSpeaks();
    }
  }

  void _toggleCamera() {
    HapticFeedback.selectionClick();
    setState(() => _cameraOn = !_cameraOn);
  }

  void _toggleCaptions() {
    HapticFeedback.selectionClick();
    setState(() => _captionsOn = !_captionsOn);
  }

  Future<void> _openTypeSheet() async {
    if (_ended) return;
    _textController.clear();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.pale,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.keyboard_alt_outlined,
                        color: AppColors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type your reply',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Your partner will answer out loud.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _textController,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (value) => Navigator.pop(sheetContext, value),
                  decoration: const InputDecoration(
                    hintText: 'What would you like to say?',
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'Send reply',
                  icon: Icons.send_rounded,
                  height: 52,
                  onPressed: () =>
                      Navigator.pop(sheetContext, _textController.text),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || text == null || text.trim().isEmpty) return;
    if (_listening) {
      unawaited(_speech.cancel());
      setState(() {
        _listening = false;
        _partial = '';
      });
    }
    await _handleUserText(text);
  }

  void _showCoachTip() {
    final reply = _lastReply;
    if (reply == null) return;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CoachTipSheet(reply: reply),
    );
  }

  void _openTranscript() {
    if (_history.isEmpty) return;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TranscriptSheet(
        history: _history,
        persona: widget.persona,
      ),
    );
  }

  Future<void> _endCall() async {
    if (_ending || _ended) return;
    _ending = true;
    _ended = true;
    _runId++;
    HapticFeedback.mediumImpact();
    _ticker?.cancel();
    _speakGuard?.cancel();
    _autoListen = false;
    unawaited(_speech.cancel());
    unawaited(_tts.stop());
    if (!mounted) return;

    final report = _buildReport();

    // Only save a session once the learner has actually spoken; opening a call
    // and leaving immediately should not create a 0-turn record.
    if (_userTurns > 0) {
      final record = SessionRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: DateTime.now(),
        scenarioTitle: widget.scenario.title,
        personaName: widget.persona.name,
        durationSeconds: _elapsed,
        turns: _userTurns,
        words: _wordTotal,
        fillers: _fillerTotal,
        fluency: report.fluency,
        newWords: report.vocab,
      );
      await _state.recordSession(record);
      if (!mounted) return;
    }

    await _showReport(report);
  }

  Future<void> _restart() async {
    _runId++;
    _ticker?.cancel();
    _speakGuard?.cancel();
    unawaited(_speech.cancel());
    unawaited(_tts.stop());
    if (!mounted) return;
    setState(() {
      _starting = true;
      _ended = false;
      _ending = false;
      _history = [];
      _lastReply = null;
      _lastAiText = '';
      _partial = '';
      _elapsed = 0;
      _userTurns = 0;
      _wordTotal = 0;
      _fillerTotal = 0;
      _listening = false;
      _thinking = false;
      _aiSpeaking = false;
      _micMuted = false;
      _showTypeFallback = false;
      _emptyListens = 0;
      _status = 'Reconnecting…';
    });
    await _begin();
  }

  Future<void> _showReport(CallReport report) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _CallReportSheet(report: report),
    );
    if (!mounted) return;
    if (action == 'again') {
      await _restart();
    } else {
      Navigator.of(context).pop();
    }
  }

  CallReport _buildReport() {
    final reply = _lastReply;
    final minutes = math.max(_elapsed / 60, 0.35);
    final wpm = (_wordTotal / minutes).round();

    var fluency = 46.0 +
        math.min(28.0, _userTurns * 4.5) +
        math.min(20.0, _wordTotal / 7.0) -
        _fillerTotal * 3.0;
    if (_wordTotal >= 40) fluency += 4;
    if (_elapsed < 20 && _userTurns < 2) fluency -= 6;
    final score = fluency.clamp(25, 97).round();

    final strengths = <String>[
      if (_userTurns > 0)
        'You answered $_userTurns ${_userTurns == 1 ? 'time' : 'times'} and kept the scene moving.',
      if (_fillerTotal <= 1 && _wordTotal > 10)
        'Your delivery was clean with almost no filler words.',
      if (reply != null && reply.betterWay.trim().isEmpty)
        'Your last sentence already sounded natural — nice!',
      if (_wordTotal >= 30) 'You produced $_wordTotal words in this call.',
    ];
    if (strengths.isEmpty) {
      strengths.add('You showed up and started speaking — that is the hardest part.');
    }

    final improvements = <String>[
      if (reply != null && reply.correction.trim().isNotEmpty) reply.correction,
      if (_fillerTotal >= 2)
        'Replace “um”, “like” and “actually” with a short pause.',
      if (wpm > 0 && wpm < 65)
        'Link your ideas so you can speak a little faster.',
      if (wpm > 165) 'Slow down slightly and finish each word clearly.',
      if (reply != null && reply.betterWay.trim().isNotEmpty)
        'Say the natural version out loud: “${reply.betterWay}”',
      'Reuse today’s new word in your next call.',
    ];

    final vocab = <String>[
      if (reply != null && reply.vocabWord.trim().isNotEmpty)
        reply.vocabWord.trim(),
    ];

    return CallReport(
      scenario: widget.scenario,
      persona: widget.persona,
      durationSeconds: _elapsed,
      turns: _userTurns,
      words: _wordTotal,
      fillers: _fillerTotal,
      fluency: score,
      betterWay: reply?.betterWay ?? '',
      casualTone: reply?.casualTone ?? '',
      formalTone: reply?.formalTone ?? '',
      idiomaticTone: reply?.idiomaticTone ?? '',
      banglaTip: reply?.banglaTip ?? '',
      vocab: vocab,
      strengths: strengths,
      improvements: improvements,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final persona = widget.persona;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_endCall());
      },
      child: Scaffold(
        backgroundColor: AppColors.deep,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF21103F), Color(0xFF170A2E), Color(0xFF2A0E5C)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                left: -90,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: persona.colors.first.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                bottom: -140,
                right: -100,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mint.withValues(alpha: 0.07),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final avatarSize = math
                              .min(
                                constraints.maxWidth * 0.56,
                                constraints.maxHeight * 0.56,
                              )
                              .clamp(140.0, 240.0)
                              .toDouble();
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Spacer(),
                                    TalkingAvatar(
                                      persona: persona,
                                      imageBase64:
                                          persona.isCustom && _state.voice.hasPhoto
                                              ? _state.voice.photoBase64
                                              : '',
                                      size: avatarSize,
                                      talking: _aiSpeaking,
                                      showRings: true,
                                      statusText: _status,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      persona.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${persona.role} • ${persona.accent}',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.58),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 20,
                                top: 10,
                                child: _ScenarioChip(scenario: widget.scenario),
                              ),
                              Positioned(
                                right: 20,
                                bottom: 8,
                                child: _SelfView(
                                  cameraOn: _cameraOn,
                                  name: _state.firstName,
                                  avatarBase64: _state.avatarBase64,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (_captionsOn) _buildSubtitles(),
                    if (_hasCoachTip) _buildCoachTip(),
                    if (_showTypeFallback && !_listening && !_thinking)
                      _buildTypeFallback(),
                    _buildControls(),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Voice stays on this device',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.32),
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          '  •  ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.18),
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          _starting ? 'Connecting' : _sourceLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.32),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: _endCall,
            tooltip: 'End call',
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.rose,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 10,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                const SizedBox(width: 8),
                Text(
                  AppUtils.formatDuration(_elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _GlassIconButton(
            icon: Icons.forum_outlined,
            onTap: _openTranscript,
            tooltip: 'Transcript',
          ),
          const SizedBox(width: 8),
          _GlassIconButton(
            icon: _speakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            onTap: _toggleSpeaker,
            tooltip: _speakerOn ? 'Mute speaker' : 'Turn speaker on',
            active: !_speakerOn,
          ),
          const SizedBox(width: 8),
          _GlassIconButton(
            icon: _captionsOn
                ? Icons.closed_caption_rounded
                : Icons.closed_caption_off_rounded,
            onTap: _toggleCaptions,
            tooltip: 'Live subtitles',
            active: _captionsOn,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitles() {
    final persona = widget.persona;
    // Keep the coach's last line visible while the user speaks; the partial
    // transcript replaces it only when there is something to show.
    final displayText = _partial.isNotEmpty
        ? _partial
        : (_thinking
            ? 'Putting a thoughtful reply together…'
            : _lastAiText);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B0D35).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: persona.colors),
                ),
                alignment: Alignment.center,
                child: Text(
                  persona.emoji,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _listening ? 'You are speaking' : 'Live subtitles',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_aiSpeaking)
                const WaveformBars(
                  active: true,
                  color: AppColors.mint,
                  bars: 4,
                  height: 14,
                  barWidth: 2.4,
                  spacing: 2.4,
                )
              else
                Text(
                  _sourceLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.34),
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white.withValues(alpha: 0.08),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _openTypeSheet,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.keyboard_alt_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            child: Text(
              displayText,
              key: ValueKey('$displayText|$_listening|$_thinking'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: displayText.isEmpty ? 0.4 : 0.92,
                ),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (_listening && _partial.isNotEmpty) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(AppColors.mint),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoachTip() {
    final reply = _lastReply!;
    final tip = reply.correction.trim().isNotEmpty
        ? reply.correction
        : (reply.betterWay.trim().isNotEmpty
            ? 'More natural: ${reply.betterWay}'
            : reply.banglaTip);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: AppColors.mint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _showCoachTip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.mint,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 10.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFallback() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: const Color(0xFF1B0D35).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _openTypeSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.keyboard_alt_outlined,
                    color: AppColors.amber,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mic not picking up? Type your reply instead.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 10.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Type',
                  style: TextStyle(
                    color: AppColors.mint.withValues(alpha: 0.95),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallControl(
            icon: _micMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
            label: _micMuted ? 'Unmute' : 'Mute',
            onTap: _toggleMute,
            background: _micMuted
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.11),
            iconColor: _micMuted ? AppColors.deep : Colors.white,
          ),
          _CallControl(
            icon: _listening
                ? Icons.stop_rounded
                : (_micMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
            label: _listening
                ? 'Send'
                : (_micMuted ? 'Unmute' : 'Speak'),
            onTap: _tapMic,
            big: true,
            active: _listening,
            background: _listening ? AppColors.mint : Colors.white,
            iconColor: _listening ? Colors.white : AppColors.deep,
          ),
          _CallControl(
            icon: _cameraOn
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: 'Camera',
            onTap: _toggleCamera,
            background: _cameraOn
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.11),
            iconColor: _cameraOn ? AppColors.deep : Colors.white,
          ),
          _CallControl(
            icon: Icons.call_end_rounded,
            label: 'End',
            onTap: _endCall,
            background: AppColors.rose,
            iconColor: Colors.white,
            big: true,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small widgets
// -----------------------------------------------------------------------------

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: active
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _ScenarioChip extends StatelessWidget {
  const _ScenarioChip({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(scenario.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              scenario.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfView extends StatelessWidget {
  const _SelfView({
    required this.cameraOn,
    required this.name,
    required this.avatarBase64,
  });

  final bool cameraOn;
  final String name;
  final String avatarBase64;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 100,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF241043),
            gradient: cameraOn
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                  )
                : null,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: cameraOn
              ? Center(
                  child: UserAvatar(
                    base64: avatarBase64,
                    name: name,
                    size: 52,
                    border: false,
                  ),
                )
              : Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white54,
                      size: 17,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          'You',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.background,
    required this.iconColor,
    this.big = false,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color iconColor;
  final bool big;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final size = big ? 56.0 : 46.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.mint.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: iconColor, size: big ? 25 : 21),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.66),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Report sheet
// -----------------------------------------------------------------------------

class _CallReportSheet extends StatelessWidget {
  const _CallReportSheet({required this.report});

  final CallReport report;

  @override
  Widget build(BuildContext context) {
    final hasTones = report.casualTone.trim().isNotEmpty ||
        report.formalTone.trim().isNotEmpty ||
        report.idiomaticTone.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.mintDeep,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Call ended — great work!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${report.scenario.title} • ${report.persona.name}',
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
                  ],
                ),
                const SizedBox(height: 16),
                _ScoreHero(report: report),
                if (report.betterWay.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _ReportLabel(text: 'MORE NATURAL'),
                  const SizedBox(height: 7),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.pale,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.auto_fix_high_rounded,
                            color: AppColors.purple,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '“${report.betterWay}”',
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasTones) ...[
                  const SizedBox(height: 16),
                  const _ReportLabel(text: 'SAY IT 3 WAYS'),
                  const SizedBox(height: 7),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        if (report.casualTone.trim().isNotEmpty)
                          _ToneRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            color: AppColors.violet,
                            title: 'Casual',
                            text: report.casualTone,
                          ),
                        if (report.formalTone.trim().isNotEmpty)
                          _ToneRow(
                            icon: Icons.badge_outlined,
                            color: const Color(0xFF0284C7),
                            title: 'Formal',
                            text: report.formalTone,
                            divided: report.casualTone.trim().isNotEmpty,
                          ),
                        if (report.idiomaticTone.trim().isNotEmpty)
                          _ToneRow(
                            icon: Icons.auto_awesome_outlined,
                            color: AppColors.mintDeep,
                            title: 'Idiomatic',
                            text: report.idiomaticTone,
                            divided: report.casualTone.trim().isNotEmpty ||
                                report.formalTone.trim().isNotEmpty,
                          ),
                      ],
                    ),
                  ),
                ],
                if (report.banglaTip.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.mint.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.mintDeep,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report.banglaTip,
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.55,
                              color: AppColors.mintDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (report.vocab.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: report.vocab
                        .map(
                          (word) => Pill(
                            label: word,
                            icon: Icons.auto_stories_rounded,
                            color: AppColors.purple,
                            fontSize: 10,
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FeedbackCard(
                        title: 'What went well',
                        icon: Icons.thumb_up_alt_outlined,
                        color: AppColors.mintDeep,
                        background: const Color(0xFFF2FCF8),
                        items: report.strengths,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _FeedbackCard(
                        title: 'Next time',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.purple,
                        background: const Color(0xFFFAF7FF),
                        items: report.improvements,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, 'again'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          backgroundColor: AppColors.surface,
                        ),
                        child: const Text('Practice again'),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: GradientButton(
                        label: 'Done',
                        icon: Icons.check_rounded,
                        height: 54,
                        onPressed: () => Navigator.pop(context, 'done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.report});

  final CallReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          ScoreRing(
            value: report.fluency / 100,
            size: 92,
            stroke: 7,
            dark: true,
            color: AppColors.mint,
            displayText: '${report.fluency}',
            label: 'fluency',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppUtils.formatDuration(report.durationSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                _HeroStat(
                  label: 'Your turns',
                  value: '${report.turns}',
                ),
                const SizedBox(height: 7),
                _HeroStat(
                  label: 'Words spoken',
                  value: '${report.words}',
                ),
                const SizedBox(height: 7),
                _HeroStat(
                  label: 'Filler words',
                  value: '${report.fillers}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReportLabel extends StatelessWidget {
  const _ReportLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.muted,
      ),
    );
  }
}

class _ToneRow extends StatelessWidget {
  const _ToneRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    this.divided = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: divided
            ? const Border(top: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.ink,
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

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color background;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...items.take(4).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.45,
                            color: AppColors.ink,
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

// -----------------------------------------------------------------------------
// Coach tip sheet
// -----------------------------------------------------------------------------

class _CoachTipSheet extends StatelessWidget {
  const _CoachTipSheet({required this.reply});

  final AiReply reply;

  @override
  Widget build(BuildContext context) {
    final hasTones = reply.casualTone.trim().isNotEmpty ||
        reply.formalTone.trim().isNotEmpty ||
        reply.idiomaticTone.trim().isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Coach’s note',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              if (reply.correction.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    reply.correction,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.55,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (reply.betterWay.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                const _ReportLabel(text: 'MORE NATURAL'),
                const SizedBox(height: 6),
                Text(
                  '“${reply.betterWay}”',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
              if (hasTones) ...[
                const SizedBox(height: 18),
                const _ReportLabel(text: 'SAY IT 3 WAYS'),
                const SizedBox(height: 7),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      if (reply.casualTone.trim().isNotEmpty)
                        _ToneRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          color: AppColors.violet,
                          title: 'Casual',
                          text: reply.casualTone,
                        ),
                      if (reply.formalTone.trim().isNotEmpty)
                        _ToneRow(
                          icon: Icons.badge_outlined,
                          color: const Color(0xFF0284C7),
                          title: 'Formal',
                          text: reply.formalTone,
                          divided: reply.casualTone.trim().isNotEmpty,
                        ),
                      if (reply.idiomaticTone.trim().isNotEmpty)
                        _ToneRow(
                          icon: Icons.auto_awesome_outlined,
                          color: AppColors.mintDeep,
                          title: 'Idiomatic',
                          text: reply.idiomaticTone,
                          divided: reply.casualTone.trim().isNotEmpty ||
                              reply.formalTone.trim().isNotEmpty,
                        ),
                    ],
                  ),
                ),
              ],
              if (reply.banglaTip.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.translate_rounded,
                        color: AppColors.mintDeep,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reply.banglaTip,
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.55,
                            color: AppColors.mintDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (reply.hintForUser.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 16,
                      color: AppColors.purple,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Try next: ${reply.hintForUser}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          color: AppColors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              GradientButton(
                label: 'Got it',
                height: 52,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Transcript sheet
// -----------------------------------------------------------------------------

class _TranscriptSheet extends StatefulWidget {
  const _TranscriptSheet({required this.history, required this.persona});

  final List<ChatTurn> history;
  final Persona persona;

  @override
  State<_TranscriptSheet> createState() => _TranscriptSheetState();
}

class _TranscriptSheetState extends State<_TranscriptSheet> {
  bool _copied = false;

  Future<void> _copy() async {
    final text = widget.history
        .map((turn) => '${turn.role == ChatRole.user ? 'You' : widget.persona.name}: ${turn.text}')
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.pale,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.forum_outlined,
                      size: 18,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Call transcript',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${widget.history.length} turns with ${widget.persona.name}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _copy,
                    icon: Icon(
                      _copied
                          ? Icons.check_circle_rounded
                          : Icons.copy_rounded,
                      size: 15,
                    ),
                    label: Text(_copied ? 'Copied' : 'Copy'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                itemCount: widget.history.length,
                itemBuilder: (context, index) {
                  final turn = widget.history[index];
                  final isUser = turn.role == ChatRole.user;
                  return _TranscriptBubble(
                    text: turn.text,
                    speaker: isUser ? 'You' : widget.persona.name,
                    isUser: isUser,
                    emoji: widget.persona.emoji,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranscriptBubble extends StatelessWidget {
  const _TranscriptBubble({
    required this.text,
    required this.speaker,
    required this.isUser,
    required this.emoji,
  });

  final String text;
  final String speaker;
  final bool isUser;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.pale,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.purple : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? AppColors.purple : Colors.white,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'You' : speaker,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isUser ? Colors.white : AppColors.ink,
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
