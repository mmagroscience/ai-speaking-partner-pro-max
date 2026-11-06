import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../update_dialog.dart';
import 'dashboard_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../practice/practice_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _otaChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_otaChecked) return;
    _otaChecked = true;
    final state = context.read<AppState>();
    final config = await state.ota.fetch(url: state.otaUrl);
    if (!mounted) return;
    if (config.hasUpdate) {
      await showUpdateDialog(context, config);
    }
  }

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onOpenTab: _goTo),
      const PracticeScreen(),
      const FlashcardsScreen(),
      ProgressScreen(onStartPractice: () => _goTo(1)),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: AppColors.deep.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                outline: Icons.home_outlined,
                label: 'Home',
                selected: _index == 0,
                onTap: () => _goTo(0),
              ),
              _NavItem(
                icon: Icons.explore_rounded,
                outline: Icons.explore_outlined,
                label: 'Practice',
                selected: _index == 1,
                onTap: () => _goTo(1),
              ),
              _NavItem(
                icon: Icons.style_rounded,
                outline: Icons.style_outlined,
                label: 'Cards',
                selected: _index == 2,
                onTap: () => _goTo(2),
              ),
              _NavItem(
                icon: Icons.insights_rounded,
                outline: Icons.insights_outlined,
                label: 'Progress',
                selected: _index == 3,
                onTap: () => _goTo(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                outline: Icons.person_outline_rounded,
                label: 'Profile',
                selected: _index == 4,
                onTap: () => _goTo(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.outline,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData outline;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.pale : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? icon : outline,
                  size: 22,
                  color: selected ? AppColors.purple : AppColors.muted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.purple : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
