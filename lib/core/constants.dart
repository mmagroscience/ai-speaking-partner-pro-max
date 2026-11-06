import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppInfo {
  AppInfo._();
  static const name = 'AI Speaking Partner';
  static const edition = 'PRO MAX';
  static const versionName = '1.3.1';
  static const versionCode = 5;
}

const kDefaultOtaUrl = '';
const kGeminiModel = 'gemini-2.5-flash';
const kMaxCallMinutes = 60;
const kRingAsset = 'assets/audio/ring.wav';

class AppUtils {
  AppUtils._();

  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String readableMinutes(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }

  static String capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static String shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static int wordCount(String text) {
    final matches = RegExp(r"[A-Za-z0-9']+").allMatches(text);
    return matches.length;
  }

  static int countFillers(String text) {
    final lower = text.toLowerCase();
    final matches =
        RegExp(r'\b(um+|uh+|erm+|like|you know|actually|basically)\b')
            .allMatches(lower);
    return matches.length;
  }

  static double clamp(double v, [double min = 0, double max = 1]) =>
      math.max(min, math.min(max, v));

  static void showSnack(BuildContext context, String message,
      {bool error = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline,
              color: error ? AppColorsRef.rose : AppColorsRef.mint,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColorsRef.rose)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// A tiny indirection so utility code can use app colours without importing
/// the theme file everywhere.
class AppColorsRef {
  static const rose = Color(0xFFFB7185);
  static const mint = Color(0xFF10B981);
}
