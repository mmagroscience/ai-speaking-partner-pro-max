import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/models.dart';
import 'common.dart';

class TalkingAvatar extends StatefulWidget {
  const TalkingAvatar({
    super.key,
    required this.persona,
    this.imageBase64 = '',
    this.size = 180,
    this.talking = false,
    this.showRings = true,
    this.statusText,
  });

  final Persona persona;
  final String imageBase64;
  final double size;
  final bool talking;
  final bool showRings;
  final String? statusText;

  @override
  State<TalkingAvatar> createState() => _TalkingAvatarState();
}

class _TalkingAvatarState extends State<TalkingAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _mouth;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _mouth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
    );
    if (widget.talking) _mouth.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TalkingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.talking && !_mouth.isAnimating) {
      _mouth.repeat(reverse: true);
    } else if (!widget.talking && _mouth.isAnimating) {
      _mouth.stop();
      _mouth.value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _mouth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbSize = widget.size;
    final total = widget.showRings ? orbSize * 1.34 : orbSize;
    final bytes = decodeBase64Image(widget.imageBase64);
    final isPhoto = bytes != null;

    return SizedBox(
      width: total,
      height: total,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _mouth]),
        builder: (context, child) {
          final t = _breath.value;
          final ringScale = 1 + math.sin(t * math.pi * 2) * 0.025;
          final blink = t > 0.965 ? 0.12 : 1.0;
          final mouthOpen = widget.talking
              ? 0.45 + (math.sin(_mouth.value * math.pi * 2) + 1) / 2 * 0.55
              : 0.10;
          final tiltX = math.sin(t * math.pi * 2) * 0.025;
          final tiltY = math.cos(t * math.pi * 2) * 0.035;

          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.showRings) ...[
                Transform.scale(
                  scale: ringScale,
                  child: Container(
                    width: orbSize * 1.28,
                    height: orbSize * 1.28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.persona.colors.first
                            .withValues(alpha: 0.18),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: ringScale * 1.03,
                  child: Container(
                    width: orbSize * 1.16,
                    height: orbSize * 1.16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.persona.colors.first
                            .withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
              CustomPaint(
                size: Size(orbSize * 1.18, orbSize * 1.18),
                painter: _AuraPainter(
                  colors: widget.persona.colors,
                  phase: t,
                ),
              ),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(tiltX)
                  ..rotateY(tiltY),
                child: Container(
                  width: orbSize,
                  height: orbSize,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(
                        color: widget.persona.colors.last
                            .withValues(alpha: 0.35),
                        blurRadius: 26,
                        spreadRadius: 2,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.6),
                        blurRadius: 8,
                        offset: const Offset(-4, -6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isPhoto)
                          Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            gaplessPlayback: true,
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: widget.persona.colors,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -orbSize * 0.12,
                                  left: -orbSize * 0.05,
                                  child: Container(
                                    width: orbSize * 0.55,
                                    height: orbSize * 0.55,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withValues(alpha: 0.14),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    widget.persona.emoji,
                                    style: TextStyle(
                                      fontSize: orbSize * 0.34,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.18),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Soft studio light across the face.
                        Positioned(
                          top: -orbSize * 0.25,
                          left: -orbSize * 0.1,
                          child: Transform.rotate(
                            angle: -0.4,
                            child: Container(
                              width: orbSize * 0.45,
                              height: orbSize * 0.85,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.20),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(orbSize * 0.3),
                              ),
                            ),
                          ),
                        ),
                        if (!isPhoto) ...[
                          Positioned(
                            top: orbSize * 0.33,
                            left: orbSize * 0.25,
                            right: orbSize * 0.25,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _Eye(blink: blink, size: orbSize * 0.095),
                                _Eye(blink: blink, size: orbSize * 0.095),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: orbSize * 0.23,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                width: orbSize *
                                    (0.16 + (widget.talking ? 0.035 : 0)),
                                height: orbSize * 0.11 * mouthOpen + 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B1728)
                                      .withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(
                                    orbSize * 0.08,
                                  ),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.18),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else
                          Positioned(
                            bottom: orbSize * 0.16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                width: orbSize *
                                    (0.15 + (widget.talking ? 0.04 : 0)),
                                height: orbSize * 0.085 * mouthOpen + 1,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A1327)
                                      .withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(
                                    orbSize * 0.08,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: orbSize * 0.26,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.statusText != null)
                Positioned(
                  bottom: widget.showRings ? 0 : -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.deep.withValues(alpha: 0.85),
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
                        const SizedBox(width: 6),
                        Text(
                          widget.statusText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye({required this.blink, required this.size});

  final double blink;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleY: blink,
      child: Container(
        width: size,
        height: size * 1.12,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(size),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: size * 0.46,
            height: size * 0.46,
            decoration: const BoxDecoration(
              color: Color(0xFF2C1836),
              shape: BoxShape.circle,
            ),
            child: Align(
              alignment: const Alignment(-0.3, -0.35),
              child: Container(
                width: size * 0.14,
                height: size * 0.14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({required this.colors, required this.phase});

  final List<Color> colors;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.first.withValues(alpha: 0.30),
          colors.last.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.45, 0.75, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glow);

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.first.withValues(alpha: 0.20);
    canvas.drawCircle(center, radius * 0.93, orbit);

    final dotAngle = phase * math.pi * 2 - math.pi / 2;
    final dot = Offset(
      center.dx + math.cos(dotAngle) * radius * 0.92,
      center.dy + math.sin(dotAngle) * radius * 0.92,
    );
    canvas.drawCircle(
      dot,
      3.2,
      Paint()..color = colors.first.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) =>
      old.phase != phase || old.colors != colors;
}
