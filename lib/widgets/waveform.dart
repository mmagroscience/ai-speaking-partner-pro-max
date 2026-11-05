import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class WaveformBars extends StatefulWidget {
  const WaveformBars({
    super.key,
    this.active = true,
    this.color = AppColors.mint,
    this.bars = 5,
    this.height = 22,
    this.barWidth = 3,
    this.spacing = 3,
  });

  final bool active;
  final Color color;
  final int bars;
  final double height;
  final double barWidth;
  final double spacing;

  @override
  State<WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WaveformBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.bars, (i) {
            final phase = (_controller.value * math.pi * 2) + i * 0.75;
            final strength = widget.active
                ? (math.sin(phase) + 1) / 2
                : 0.18 + (i % 3) * 0.12;
            final height = 4 + (widget.height - 4) * strength;
            return Container(
              margin: EdgeInsets.only(right: i == widget.bars - 1 ? 0 : widget.spacing),
              width: widget.barWidth,
              height: height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.barWidth),
              ),
            );
          }),
        );
      },
    );
  }
}

class AudioOrb extends StatelessWidget {
  const AudioOrb({
    super.key,
    required this.icon,
    this.size = 46,
    this.color = AppColors.purple,
    this.background,
    this.onTap,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Color? background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: color, size: size * 0.44),
        ),
      ),
    );
  }
}
