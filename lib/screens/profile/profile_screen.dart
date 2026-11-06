import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../admin/admin_gate.dart';
import '../flashcards/flashcards_screen.dart';
import '../practice/voice_clone_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final voice = state.voice;

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 112),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Your goals, your voice, your pace.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            UserAvatar(
                              base64: state.avatarBase64,
                              name: state.firstName,
                              size: 76,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Material(
                                color: AppColors.purple,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _pickAvatar(context, state),
                                  child: const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      state.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _editName(context, state),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 17,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 5,
                                children: [
                                  LevelPill(level: state.level),
                                  Pill(
                                    label: state.goal.label,
                                    icon: Icons.flag_outlined,
                                    color: AppColors.mintDeep,
                                    background: AppColors.mintSoft,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                state.avatarBase64.isEmpty
                                    ? 'Add a photo so your coach can greet you properly.'
                                    : 'Looking good. Your coach recognises you now.',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetric(
                            value: '${state.totalSessions}',
                            label: 'sessions',
                          ),
                        ),
                        _VerticalDivider(),
                        Expanded(
                          child: _MiniMetric(
                            value: AppUtils.readableMinutes(state.totalMinutes),
                            label: 'spoken',
                          ),
                        ),
                        _VerticalDivider(),
                        Expanded(
                          child: _MiniMetric(
                            value: state.streak == 0 ? '0' : '${state.streak}',
                            label: 'streak',
                          ),
                        ),
                        _VerticalDivider(),
                        Expanded(
                          child: _MiniMetric(
                            value: '${state.flashKnown.length}',
                            label: 'words',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.pale,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(state.goal.icon,
                          color: AppColors.purple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Speaking goal',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            state.goal.label,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            state.helpLabelForGoal,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickGoal(context, state),
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VoiceCloneScreen(),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: voice.hasPhoto
                            ? null
                            : AppColors.peachGradient,
                        color: voice.hasPhoto ? AppColors.pale : null,
                        borderRadius: BorderRadius.circular(14),
                        image: voice.hasPhoto
                            ? DecorationImage(
                                image: MemoryImage(
                                  base64Decode(voice.photoBase64),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: voice.hasPhoto
                          ? null
                          : const Icon(Icons.family_restroom_rounded,
                              color: Colors.white, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Familiar person',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Pill(
                                label: voice.cloned ? 'VOICE READY' : 'SET UP',
                                color: voice.cloned
                                    ? AppColors.mintDeep
                                    : AppColors.amber,
                                background: voice.cloned
                                    ? AppColors.mintSoft
                                    : AppColors.amberSoft,
                                fontSize: 8,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            voice.cloned
                                ? 'Call ${voice.displayName} with your cloned voice.'
                                : 'Upload a photo and a 10–30s voice clip.',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.muted),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Settings'),
              _ActionRow(
                icon: Icons.style_rounded,
                title: 'Flashcards · Oxford 3000',
                subtitle: 'Baby → University • ${state.flashKnown.length} words known',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.tune_rounded,
                title: 'AI, voice & app settings',
                subtitle: 'API keys, auto-speak, OTA link',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin & OTA panel',
                subtitle: 'Publish topics and app updates',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminGateScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy & data',
                subtitle: 'What stays on this device',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.info_outline_rounded,
                title: 'About this app',
                subtitle: 'Version ${AppInfo.versionName} • PRO MAX',
                onTap: () => _showAbout(context),
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    const AppLogo(size: 38),
                    const SizedBox(height: 8),
                    Text(
                      '${AppInfo.name} ${AppInfo.edition}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'Made for Bangladeshi learners, with love.',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.muted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context, AppState state) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 72,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 900000) {
        if (context.mounted) {
          AppUtils.showSnack(context, 'That photo is too large. Try a smaller one.',
              error: true);
        }
        return;
      }
      await state.setAvatarBase64(base64Encode(bytes));
      if (context.mounted) {
        AppUtils.showSnack(context, 'Profile photo saved.');
      }
    } catch (e) {
      if (context.mounted) {
        AppUtils.showSnack(context, 'Could not open the gallery on this device.',
            error: true);
      }
    }
  }

  Future<void> _editName(BuildContext context, AppState state) async {
    final controller = TextEditingController(text: state.name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What should we call you?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await state.setName(value);
  }

  Future<void> _pickGoal(BuildContext context, AppState state) async {
    final selected = await showModalBottomSheet<AppGoal>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your speaking goal',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Every call will adapt to the goal you choose.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...AppGoal.values.map(
              (goal) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.pale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(goal.icon, color: AppColors.purple, size: 20),
                ),
                title: Text(goal.label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(goal.blurb,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10)),
                trailing: state.goal == goal
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.purple)
                    : null,
                onTap: () => Navigator.pop(context, goal),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await state.setGoal(selected);
  }

  Future<void> _showAbout(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const AppLogo(size: 54),
        title: const Text('AI Speaking Partner PRO MAX'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Face-to-face AI video calls, pronunciation coaching, IELTS mock tests and a 3-tone vocabulary bank — built for learners who feel nervous speaking English.',
              style: TextStyle(fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Version ${AppInfo.versionName} (${AppInfo.versionCode})',
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: AppColors.line);
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.pale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.purple, size: 19),
              ),
              const SizedBox(width: 11),
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
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
