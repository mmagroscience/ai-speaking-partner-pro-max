import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/models.dart';

Uint8List? decodeBase64Image(String value) {
  if (value.isEmpty) return null;
  try {
    return base64Decode(value);
  } catch (_) {
    return null;
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.base64,
    required this.name,
    this.size = 44,
    this.border = true,
  });

  final String base64;
  final String name;
  final double size;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final bytes = decodeBase64Image(base64);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
        ),
        border: border
            ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.deep.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
          : Center(
              child: Text(
                _initial(name),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.38,
                ),
              ),
            ),
    );
  }

  static String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Y';
    return trimmed[0].toUpperCase();
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 24,
    this.shadow = true,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.7),
        ),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: AppColors.deep.withValues(alpha: 0.055),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.height = 56,
    this.expand = true,
    this.loading = false,
    this.foreground = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final double height;
  final bool expand;
  final bool loading;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final content = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: enabled
            ? (gradient ?? AppColors.heroGradient)
            : LinearGradient(
                colors: [AppColors.pale, AppColors.pale.withValues(alpha: 0.7)],
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(foreground),
              ),
            ),
            const SizedBox(width: 10),
          ] else if (icon != null) ...[
            Icon(icon, color: enabled ? foreground : AppColors.muted, size: 20),
            const SizedBox(width: 9),
          ],
          Text(
            label,
            style: TextStyle(
              color: enabled ? foreground : AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onPressed : null,
        child: content,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.purple,
    this.background,
    this.fontSize = 11,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color? background;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LevelPill extends StatelessWidget {
  const LevelPill({super.key, required this.level, this.dark = false});

  final CefrLevel level;
  final bool dark;

  Color get _color => switch (level) {
        CefrLevel.beginner => AppColors.mintDeep,
        CefrLevel.intermediate => const Color(0xFFB45309),
        CefrLevel.advanced => AppColors.violet,
      };

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: level.label,
      icon: level.icon,
      color: dark ? Colors.white : _color,
      background: dark
          ? Colors.white.withValues(alpha: 0.18)
          : _color.withValues(alpha: 0.10),
    );
  }
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.value,
    this.size = 96,
    this.stroke = 8,
    this.label,
    this.color = AppColors.violet,
    this.background = AppColors.pale,
    this.dark = false,
    this.displayText,
  });

  final double value;
  final double size;
  final double stroke;
  final String? label;
  final Color color;
  final Color background;
  final bool dark;
  final String? displayText;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  value: animated,
                  stroke: stroke,
                  color: color,
                  background:
                      dark ? Colors.white.withValues(alpha: 0.15) : background,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayText ?? '${(animated * 100).round()}',
                    style: TextStyle(
                      fontSize: size * 0.27,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : AppColors.ink,
                      height: 1,
                    ),
                  ),
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: size * 0.10,
                        color: dark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.background,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = background;
    canvas.drawCircle(center, radius, bgPaint);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -1.57,
        endAngle: 4.71,
        colors: [color.withValues(alpha: 0.55), color],
      ).createShader(rect);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * value,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.stroke != stroke ||
      old.background != background;
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.purple,
    this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deep.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.dark = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          if (onBack != null) ...[
            _CircleIcon(
              icon: Icons.arrow_back_rounded,
              onTap: onBack!,
              dark: dark,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : AppColors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.65)
                          : AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap, this.dark = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: dark ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.pale,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.purple, size: 26),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.count,
    required this.index,
    this.activeColor = AppColors.purple,
  });

  final int count;
  final int index;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i <= index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : AppColors.line,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 54, this.showText = false});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        color: Colors.white,
        size: size * 0.48,
      ),
    );
    if (!showText) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Speaking Partner',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
            Text(
              'PRO MAX',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.purple.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
