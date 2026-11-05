import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../admin/admin_gate.dart';
import '../update_dialog.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _otaController;
  bool _savingOta = false;

  @override
  void initState() {
    super.initState();
    _otaController =
        TextEditingController(text: context.read<AppState>().otaUrl);
  }

  @override
  void dispose() {
    _otaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HeaderBar(title: 'Settings', onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                        title: 'AI coaching',
                        trailing: Pill(
                          label: state.apiKeys.isEmpty
                              ? 'OFFLINE COACH'
                              : '${state.apiKeys.length} KEY${state.apiKeys.length == 1 ? '' : 'S'}',
                          color: state.apiKeys.isEmpty
                              ? AppColors.amber
                              : AppColors.mintDeep,
                          background: state.apiKeys.isEmpty
                              ? AppColors.amberSoft
                              : AppColors.mintSoft,
                        ),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.key_rounded,
                                    size: 19, color: AppColors.purple),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Gemini API keys',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _addKey(context, state),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.apiKeys.isEmpty
                                  ? 'No key yet — the built-in offline coach will handle every call. Add one or more keys to unlock live Gemini replies and 3-tone rewrites.'
                                  : 'Keys are tried in rotation. If one hits its quota, the next key takes over automatically.',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.muted,
                                height: 1.45,
                              ),
                            ),
                            if (state.apiKeys.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...state.apiKeys.asMap().entries.map(
                                    (entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.bg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: const BoxDecoration(
                                                color: AppColors.mintSoft,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${entry.key + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.mintDeep,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _mask(entry.value),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'Poppins',
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () => state
                                                  .removeApiKey(entry.value),
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 17,
                                                color: AppColors.rose,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.sky.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 17, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Keys are stored in the platform keystore on mobile (browser storage on web) and are never shared between apps. For a public release, route Gemini calls through your own backend so keys are never shipped in the APK.',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  height: 1.45,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel(title: 'Voice'),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.graphic_eq_rounded,
                                    size: 19, color: AppColors.purple),
                                const SizedBox(width: 8),
                                const Text(
                                  'Voice failover chain',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const Spacer(),
                                Pill(
                                  label: 'LOCAL TTS ACTIVE',
                                  color: AppColors.mintDeep,
                                  background: AppColors.mintSoft,
                                  fontSize: 8,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'AI reply → cloned voice → Fish Audio → ElevenLabs → Hugging Face zero-shot → on-device TTS.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.muted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: const [
                                _EngineChip(label: 'Fish Audio', ready: false),
                                _EngineChip(label: 'ElevenLabs', ready: false),
                                _EngineChip(
                                    label: 'Hugging Face', ready: false),
                                _EngineChip(label: 'On-device TTS', ready: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel(title: 'Call experience'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            _SwitchRow(
                              icon: Icons.volume_up_outlined,
                              title: 'Speak AI replies aloud',
                              subtitle: 'Use on-device text-to-speech',
                              value: state.autoSpeak,
                              onChanged: state.setAutoSpeak,
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _SwitchRow(
                              icon: Icons.remove_red_eye_outlined,
                              title: 'Eye-contact mode',
                              subtitle: 'Show the presence indicator in calls',
                              value: state.eyeContact,
                              onChanged: state.setEyeContact,
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  14, 10, 14, 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.translate_rounded,
                                      size: 19, color: AppColors.purple),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Help language',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        Text(
                                          'Used for onboarding help and tips',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<HelpLanguage>(
                                      value: state.helpLanguage,
                                      borderRadius: BorderRadius.circular(14),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items: HelpLanguage.values
                                          .map(
                                            (lang) => DropdownMenuItem(
                                              value: lang,
                                              child: Text(lang.label),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          state.setHelpLanguage(value);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel(title: 'App updates (OTA)'),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cloud JSON link',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Point this at a Firebase Realtime DB or GitHub raw JSON file. Leave blank to use the bundled config.',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _otaController,
                              style: const TextStyle(fontSize: 11.5),
                              decoration: const InputDecoration(
                                hintText: 'https://…/ota.json',
                                prefixIcon:
                                    Icon(Icons.link_rounded, size: 18),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _checkNow(context, state),
                                    child: const Text('Check now'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _savingOta
                                        ? null
                                        : () => _saveOta(context, state),
                                    child: _savingOta
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Save link'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminGateScreen(),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: AppColors.pale.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings_outlined,
                                        size: 17, color: AppColors.purple),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Manage version, topics and publish ota.json in the admin panel',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.purple,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        size: 17, color: AppColors.purple),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel(title: 'Data'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.restart_alt_rounded,
                                  color: AppColors.amber),
                              title: const Text(
                                'Reset learning data',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Clear sessions, streak and scores. Keep your profile.',
                                style: TextStyle(fontSize: 9.5),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _resetLearning(context, state),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: const Icon(Icons.ios_share_rounded,
                                  color: AppColors.purple),
                              title: const Text(
                                'Export progress',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Copy a JSON backup of sessions, streak and topics.',
                                style: TextStyle(fontSize: 9.5),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _exportData(context, state),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: const Icon(Icons.download_rounded,
                                  color: AppColors.mintDeep),
                              title: const Text(
                                'Import progress',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Restore a backup on this device.',
                                style: TextStyle(fontSize: 9.5),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _importData(context, state),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: const Icon(Icons.delete_forever_outlined,
                                  color: AppColors.rose),
                              title: const Text(
                                'Reset everything',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Remove all data and start onboarding again.',
                                style: TextStyle(fontSize: 9.5),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _resetAll(context, state),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel(title: 'About & privacy'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined,
                              color: AppColors.purple),
                          title: const Text(
                            'Privacy & data',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'No account, no tracking — read the full policy.',
                            style: TextStyle(fontSize: 9.5),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Text(
                          'Version ${AppInfo.versionName} • ${AppInfo.edition}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.muted,
                          ),
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

  String _mask(String key) {
    if (key.length <= 10) return '••••••••';
    return '${key.substring(0, 5)}••••••${key.substring(key.length - 4)}';
  }

  Future<void> _addKey(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a Gemini API key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'AIza…',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You can add multiple keys. They are rotated automatically when a quota is reached.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add key'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (key != null && key.trim().isNotEmpty) {
      await state.addApiKey(key);
      if (context.mounted) {
        AppUtils.showSnack(context, 'API key saved. New calls will use Gemini.');
      }
    }
  }

  Future<void> _saveOta(BuildContext context, AppState state) async {
    setState(() => _savingOta = true);
    await state.setOtaUrl(_otaController.text);
    if (!mounted) return;
    setState(() => _savingOta = false);
    if (!context.mounted) return;
    AppUtils.showSnack(
      context,
      _otaController.text.trim().isEmpty
          ? 'Using the bundled OTA config.'
          : 'OTA link saved.',
    );
  }

  Future<void> _checkNow(BuildContext context, AppState state) async {
    final config = await state.ota.fetch(url: _otaController.text);
    if (!context.mounted) return;
    if (config.hasUpdate) {
      await showUpdateDialog(context, config);
      return;
    }
    if (!context.mounted) return;
    AppUtils.showSnack(
      context,
      'You are on the latest version (${AppInfo.versionName}).',
    );
  }

  Future<void> _exportData(BuildContext context, AppState state) async {
    final json = state.exportProgressJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    AppUtils.showSnack(
      context,
      'Backup copied — ${state.sessions.length} session(s). Paste it somewhere safe.',
    );
  }

  Future<void> _importData(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import progress'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste a backup created with “Export progress”. This replaces your current sessions, streak and custom topics.',
                style: TextStyle(fontSize: 11, height: 1.45),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                style: const TextStyle(fontSize: 10.5),
                decoration: const InputDecoration(
                  hintText: '{ "app": "ai-speaking-partner", … }',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty) return;
    final error = await state.importProgressJson(raw);
    if (!context.mounted) return;
    AppUtils.showSnack(
      context,
      error ?? 'Progress restored from backup.',
      error: error != null,
    );
  }

  Future<void> _resetLearning(BuildContext context, AppState state) async {
    final ok = await AppUtils.confirm(
      context,
      title: 'Reset learning data?',
      message:
          'Sessions, streak, fluency and pronunciation scores will be cleared. Your profile and API keys stay.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (ok) await state.resetLearningData();
  }

  Future<void> _resetAll(BuildContext context, AppState state) async {
    final ok = await AppUtils.confirm(
      context,
      title: 'Reset everything?',
      message:
          'This removes your profile, sessions, API keys, avatar and custom topics. It cannot be undone.',
      confirmLabel: 'Delete all',
      destructive: true,
    );
    if (!ok) return;
    await state.resetEverything();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: AppColors.muted,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.purple),
          const SizedBox(width: 10),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.purple,
          ),
        ],
      ),
    );
  }
}

class _EngineChip extends StatelessWidget {
  const _EngineChip({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ready ? AppColors.mintSoft : AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ready
              ? AppColors.mint.withValues(alpha: 0.3)
              : AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 11,
            color: ready ? AppColors.mintDeep : AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: ready ? AppColors.mintDeep : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
