import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

class AiSpeakingApp extends StatelessWidget {
  const AiSpeakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppInfo.name} ${AppInfo.edition}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 560;
            Widget content = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            );
            if (isWide) {
              content = Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deep.withValues(alpha: 0.18),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: content,
              );
            }
            return ColoredBox(
              color: isWide ? const Color(0xFFEDE7FB) : AppColors.bg,
              child: Center(child: content),
            );
          },
        );
      },
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _splashDone = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    Widget child;
    if (!_splashDone || !state.loaded) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (!state.onboarded) {
      child = const OnboardingFlow(key: ValueKey('onboarding'));
    } else {
      child = const HomeShell(key: ValueKey('home'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}
