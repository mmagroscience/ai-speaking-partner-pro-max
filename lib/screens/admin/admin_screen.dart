import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../update_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final TextEditingController _versionCode;
  late final TextEditingController _versionName;
  late final TextEditingController _apkUrl;
  late final TextEditingController _changelog;

  @override
  void initState() {
    super.initState();
    _versionCode =
        TextEditingController(text: '${AppInfo.versionCode + 1}');
    _versionName = TextEditingController(text: '1.1.1');
    _apkUrl =
        TextEditingController(text: 'https://example.com/app-release.apk');
    _changelog = TextEditingController(
      text:
          '• New practice topics\n• Smoother video calls\n• Better pronunciation tips',
    );
  }

  @override
  void dispose() {
    _versionCode.dispose();
    _versionName.dispose();
    _apkUrl.dispose();
    _changelog.dispose();
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
              HeaderBar(
                title: 'Admin & OTA',
                subtitle: 'Local control room',
                onBack: () => Navigator.pop(context),
                trailing: Pill(
                  label: 'NO SERVER NEEDED',
                  color: AppColors.mintDeep,
                  background: AppColors.mintSoft,
                  fontSize: 8,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            _AdminStat(
                              value: '${state.totalSessions}',
                              label: 'sessions',
                            ),
                            _AdminDivider(),
                            _AdminStat(
                              value: '${state.sessions.length}',
                              label: 'records',
                            ),
                            _AdminDivider(),
                            _AdminStat(
                              value: '${state.allScenarios.length}',
                              label: 'topics',
                            ),
                            _AdminDivider(),
                            _AdminStat(
                              value: '${state.apiKeys.length}',
                              label: 'AI keys',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        title: 'Publish an app update',
                        subtitle:
                            'Generate ota.json and host it anywhere public',
                        padding: EdgeInsets.only(bottom: 10),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _versionCode,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Version code',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _versionName,
                                    decoration: const InputDecoration(
                                      labelText: 'Version name',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _apkUrl,
                              style: const TextStyle(fontSize: 11.5),
                              decoration: const InputDecoration(
                                labelText: 'APK download URL',
                                prefixIcon:
                                    Icon(Icons.link_rounded, size: 18),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _changelog,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 11.5),
                              decoration: const InputDecoration(
                                labelText: 'What\'s new',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GradientButton(
                              label: 'Generate ota.json',
                              icon: Icons.code_rounded,
                              onPressed: () => _generate(context, state),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Next step: upload the JSON to GitHub raw, Firebase Realtime Database or any URL, then paste that URL in Settings → App updates. The app checks it on every launch.',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Practice topics',
                        subtitle:
                            '${state.customScenarios.length} custom topic${state.customScenarios.length == 1 ? '' : 's'}',
                        actionLabel: 'Add topic',
                        onAction: () => _addTopic(context, state),
                        padding: const EdgeInsets.only(bottom: 10),
                      ),
                      if (state.customScenarios.isEmpty)
                        const EmptyState(
                          icon: Icons.topic_outlined,
                          title: 'No custom topics yet',
                          message:
                              'Add a scenario and it appears in Practice immediately — no store update needed.',
                        )
                      else
                        ...state.customScenarios.map(
                          (scenario) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white),
                            ),
                            child: Row(
                              children: [
                                Text(scenario.emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        scenario.title,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      Text(
                                        '${scenario.category} • ${scenario.level.label}',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      state.removeCustomScenario(scenario.id),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.rose,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        title: 'API key health',
                        subtitle: 'Automatic circular failover',
                      ),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  state.apiKeys.isEmpty
                                      ? Icons.cloud_off_rounded
                                      : Icons.cloud_done_rounded,
                                  color: state.apiKeys.isEmpty
                                      ? AppColors.amber
                                      : AppColors.mintDeep,
                                  size: 20,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    state.apiKeys.isEmpty
                                        ? 'Offline coach active — add a Gemini key in Settings.'
                                        : '${state.apiKeys.length} key(s) in rotation. Failed keys fall through automatically.',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: state.apiKeys.isEmpty ? 0.35 : 1,
                                minHeight: 5,
                                backgroundColor: AppColors.pale,
                                valueColor: AlwaysStoppedAnimation(
                                  state.apiKeys.isEmpty
                                      ? AppColors.amber
                                      : AppColors.mint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        title: 'Admin security',
                        subtitle: 'Keep the control room on this device',
                      ),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    size: 20, color: AppColors.purple),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    state.usesDefaultAdminPin
                                        ? 'The default PIN is still active. Change it before sharing this phone.'
                                        : 'A custom admin PIN protects this panel.',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.muted,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                                Pill(
                                  label: state.usesDefaultAdminPin
                                      ? 'DEFAULT'
                                      : 'CUSTOM',
                                  color: state.usesDefaultAdminPin
                                      ? AppColors.amber
                                      : AppColors.mintDeep,
                                  background: state.usesDefaultAdminPin
                                      ? AppColors.amberSoft
                                      : AppColors.mintSoft,
                                  fontSize: 8,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _changeAdminPin(context, state),
                              icon: const Icon(Icons.password_rounded, size: 17),
                              label: const Text('Change admin PIN'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.amberSoft.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: Color(0xFFB45309)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This admin panel is local to the device so you can manage the app without hosting a server. For a team, move these controls to admin_panel.html with Firebase Auth.',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  height: 1.45,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
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

  Future<void> _changeAdminPin(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    final confirm = TextEditingController();
    String? error;

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final pin = controller.text.trim();
            if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
              setDialogState(() => error = 'Use 4 to 8 digits.');
              return;
            }
            if (pin != confirm.text.trim()) {
              setDialogState(() => error = 'The two PINs do not match.');
              return;
            }
            Navigator.pop(dialogContext, pin);
          }

          return AlertDialog(
            title: const Text('Change admin PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                    counterText: '',
                    prefixIcon: Icon(Icons.password_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm new PIN',
                    counterText: '',
                    prefixIcon: Icon(Icons.check_circle_outline, size: 18),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.rose,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(onPressed: submit, child: const Text('Save PIN')),
            ],
          );
        },
      ),
    );
    controller.dispose();
    confirm.dispose();
    if (value == null) return;
    final saved = await state.setAdminPin(value);
    if (!context.mounted) return;
    AppUtils.showSnack(
      context,
      saved ? 'Admin PIN updated.' : 'Could not save that PIN.',
      error: !saved,
    );
  }

  Future<void> _generate(BuildContext context, AppState state) async {
    final code = int.tryParse(_versionCode.text.trim()) ?? 2;
    final json = state.buildOtaJson(
      versionCode: code,
      versionName: _versionName.text.trim().isEmpty
          ? '1.0.$code'
          : _versionName.text.trim(),
      apkUrl: _apkUrl.text.trim(),
      changelog: _changelog.text.trim(),
      forceUpdate: false,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ota.json',
                style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Copy this into a public JSON file. The app reads it on launch.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deep,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  json,
                  style: const TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: json));
                      if (sheetContext.mounted) {
                        AppUtils.showSnack(
                            sheetContext, 'ota.json copied.');
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: const Text('Copy JSON'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showUpdateDialog(
                        context,
                        OtaConfig(
                          latestVersionCode: code,
                          latestVersionName: _versionName.text.trim(),
                          apkUrl: _apkUrl.text.trim(),
                          changelog: _changelog.text.trim(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 17),
                    label: const Text('Preview'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTopic(BuildContext context, AppState state) async {
    final scenario = await showDialog<Scenario>(
      context: context,
      builder: (_) => const _AddTopicDialog(),
    );
    if (scenario != null) {
      await state.addCustomScenario(scenario);
      if (context.mounted) {
        AppUtils.showSnack(context, 'Topic added to Practice.');
      }
    }
  }
}

class _AdminStat extends StatelessWidget {
  const _AdminStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDivider extends StatelessWidget {
  const _AdminDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}

class _AddTopicDialog extends StatefulWidget {
  const _AddTopicDialog();

  @override
  State<_AddTopicDialog> createState() => _AddTopicDialogState();
}

class _AddTopicDialogState extends State<_AddTopicDialog> {
  final _title = TextEditingController();
  final _opening = TextEditingController();
  final _role = TextEditingController(text: 'A friendly conversation partner');
  String _category = 'Everyday English';
  CefrLevel _level = CefrLevel.intermediate;
  String _personaId = 'sarah';
  String _emoji = '✨';

  @override
  void dispose() {
    _title.dispose();
    _opening.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a practice topic'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Topic title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _opening,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Opening line',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _role,
                decoration: const InputDecoration(labelText: 'AI role'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: Catalog.categories
                    .skip(1)
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CefrLevel>(
                      initialValue: _level,
                      decoration: const InputDecoration(labelText: 'Level'),
                      items: CefrLevel.values
                          .map((l) => DropdownMenuItem(
                              value: l, child: Text(l.label)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _level = value ?? _level),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _personaId,
                      decoration: const InputDecoration(labelText: 'Coach'),
                      items: Catalog.personas
                          .where((p) => !p.isCustom)
                          .map((p) => DropdownMenuItem(
                              value: p.id, child: Text(p.name)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _personaId = value ?? _personaId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: 'Emoji (optional)',
                  counterText: '',
                ),
                onChanged: (value) {
                  if (value.trim().isNotEmpty) _emoji = value.trim();
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              Scenario(
                id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                title: _title.text.trim(),
                subtitle: 'Your custom topic',
                category: _category,
                description: _opening.text.trim().isEmpty
                    ? 'A custom roleplay created in the admin panel.'
                    : _opening.text.trim(),
                aiRole: _role.text.trim().isEmpty
                    ? 'A friendly conversation partner'
                    : _role.text.trim(),
                openingLine: _opening.text.trim().isEmpty
                    ? 'Hey! Let\'s practise together. Tell me what you did today.'
                    : _opening.text.trim(),
                emoji: _emoji,
                level: _level,
                goals: const [
                  'Speak naturally',
                  'Handle follow-up questions',
                  'Use one new phrase',
                ],
                colors: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                personaId: _personaId,
              ),
            );
          },
          child: const Text('Add topic'),
        ),
      ],
    );
  }
}
