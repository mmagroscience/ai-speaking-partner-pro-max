import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import 'admin_screen.dart';

/// PIN gate in front of the local admin panel.
///
/// The PIN lives only on this device. It protects custom topics and OTA
/// publishing if someone else picks up an unlocked phone.
class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  final TextEditingController _pin = TextEditingController();
  final FocusNode _focus = FocusNode();
  String? _error;
  bool _unlocking = false;

  @override
  void dispose() {
    _pin.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _unlock(AppState state) async {
    if (_unlocking) return;
    setState(() {
      _unlocking = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    if (state.verifyAdminPin(_pin.text)) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    _pin.clear();
    _focus.requestFocus();
    setState(() {
      _unlocking = false;
      _error = 'That PIN does not match. Try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              HeaderBar(
                title: 'Admin access',
                subtitle: 'PIN protected',
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter your admin PIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Keep the control room for yourself — publishing updates and editing practice topics happens behind this PIN.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            TextField(
                              controller: _pin,
                              focusNode: _focus,
                              autofocus: true,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 8,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                letterSpacing: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              onSubmitted: (_) => _unlock(state),
                              decoration: InputDecoration(
                                counterText: '',
                                errorText: _error,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GradientButton(
                              label: _unlocking ? 'Unlocking…' : 'Unlock panel',
                              icon: Icons.lock_open_rounded,
                              onPressed:
                                  _unlocking ? null : () => _unlock(state),
                            ),
                            if (state.usesDefaultAdminPin) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.amberSoft.withValues(
                                    alpha: 0.55,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 15,
                                      color: Color(0xFFB45309),
                                    ),
                                    SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        'First time here? The default PIN is 1234. Change it from the panel after unlocking.',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          height: 1.4,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
}
