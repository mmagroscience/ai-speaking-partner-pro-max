import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../data/models.dart';
import '../../widgets/talking_avatar.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.scenario,
    required this.persona,
  });

  final Scenario scenario;
  final Persona persona;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  AudioPlayer? _player;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startRing();
    HapticFeedback.mediumImpact();
  }

  Future<void> _startRing() async {
    try {
      final player = AudioPlayer();
      _player = player;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.55);
      await player.play(AssetSource('audio/ring.wav'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulse.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _stopRing() async {
    try {
      await _player?.stop();
      await _player?.dispose();
      _player = null;
    } catch (_) {}
  }

  void _accept() {
    if (_answered) return;
    _answered = true;
    HapticFeedback.heavyImpact();
    _stopRing();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: CallScreen(
            scenario: widget.scenario,
            persona: widget.persona,
          ),
        ),
      ),
    );
  }

  Future<void> _decline() async {
    await _stopRing();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF241043), Color(0xFF1A0B33), Color(0xFF2A0E5C)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.persona.colors.first.withValues(alpha: 0.13),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -90,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mint.withValues(alpha: 0.07),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        _RoundButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          onTap: _decline,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
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
                              const SizedBox(width: 6),
                              const Text(
                                'INCOMING VIDEO CALL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _RoundButton(
                          icon: Icons.more_horiz_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final t = _pulse.value;
                      return SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (var i = 0; i < 2; i++)
                              Container(
                                width:
                                    210 + (t + i * 0.5) % 1 * 60,
                                height:
                                    210 + (t + i * 0.5) % 1 * 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.persona.colors.first
                                        .withValues(
                                      alpha: 0.35 *
                                          (1 - (t + i * 0.5) % 1),
                                    ),
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            TalkingAvatar(
                              persona: widget.persona,
                              size: 190,
                              showRings: false,
                              statusText: 'Ringing',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.persona.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.persona.role} • ${widget.persona.accent}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RingingText(name: widget.persona.name),
                  const SizedBox(height: 18),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 50),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.scenario.emoji,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            widget.scenario.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallAction(
                        icon: Icons.call_end_rounded,
                        label: 'Decline',
                        color: AppColors.rose,
                        onTap: _decline,
                      ),
                      _CallAction(
                        icon: Icons.videocam_rounded,
                        label: 'Answer video call',
                        color: AppColors.mint,
                        big: true,
                        onTap: _accept,
                      ),
                      const SizedBox(width: 74),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Face-to-face • live subtitles • eye contact',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingingText extends StatefulWidget {
  const _RingingText({required this.name});

  final String name;

  @override
  State<_RingingText> createState() => _RingingTextState();
}

class _RingingTextState extends State<_RingingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
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
      builder: (context, _) {
        final dots = '.' * ((_controller.value * 4).floor().clamp(0, 3));
        return Text(
          '${widget.name} is calling you$dots',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.big = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 78.0 : 62.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: big ? 34 : 27,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
