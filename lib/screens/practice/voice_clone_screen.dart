import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/talking_avatar.dart';
import '../../services/tts_service.dart';
import '../call/incoming_call_screen.dart';

class VoiceCloneScreen extends StatefulWidget {
  const VoiceCloneScreen({super.key});

  @override
  State<VoiceCloneScreen> createState() => _VoiceCloneScreenState();
}

class _VoiceCloneScreenState extends State<VoiceCloneScreen> {
  late VoiceProfile _draft;
  late final TextEditingController _nameController;
  final TtsService _tts = TtsService();
  Timer? _progressTimer;
  double _progress = 0;
  bool _cloning = false;

  @override
  void initState() {
    super.initState();
    _draft = context.read<AppState>().voice;
    _nameController = TextEditingController(
      text: _draft.displayName == 'Familiar Person' ? '' : _draft.displayName,
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _nameController.dispose();
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final persona = state.customPersona;
    final ready = _draft.hasVoice && !_cloning;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HeaderBar(
                title: 'Voice Lab',
                subtitle: 'A familiar face and voice',
                onBack: () => Navigator.pop(context),
                trailing: Pill(
                  label: _draft.cloned ? 'CLONED' : 'DEMO MODE',
                  color: _draft.cloned ? AppColors.mintDeep : AppColors.amber,
                  background:
                      _draft.cloned ? AppColors.mintSoft : AppColors.amberSoft,
                  fontSize: 8,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            TalkingAvatar(
                              persona: persona,
                              imageBase64: _draft.photoBase64,
                              size: 96,
                              showRings: false,
                              statusText: _draft.cloned ? 'Ready' : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Talk to someone familiar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Upload a photo and a 10–30 second voice clip. Your companion will keep the conversation gentle and personal.',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.muted,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 5,
                                    children: [
                                      Pill(
                                        label: 'Photo',
                                        icon: _draft.hasPhoto
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: _draft.hasPhoto
                                            ? AppColors.mintDeep
                                            : AppColors.muted,
                                        background: _draft.hasPhoto
                                            ? AppColors.mintSoft
                                            : AppColors.bg,
                                        fontSize: 8.5,
                                      ),
                                      Pill(
                                        label: 'Voice',
                                        icon: _draft.hasVoice
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: _draft.hasVoice
                                            ? AppColors.mintDeep
                                            : AppColors.muted,
                                        background: _draft.hasVoice
                                            ? AppColors.mintSoft
                                            : AppColors.bg,
                                        fontSize: 8.5,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _StepCard(
                        number: 1,
                        title: 'Add their photo',
                        subtitle: _draft.hasPhoto
                            ? 'Photo added. Tap to replace it.'
                            : 'A clear face photo works best.',
                        icon: Icons.add_a_photo_outlined,
                        done: _draft.hasPhoto,
                        onTap: _pickPhoto,
                      ),
                      const SizedBox(height: 10),
                      _StepCard(
                        number: 2,
                        title: 'Upload a voice sample',
                        subtitle: _draft.hasVoice
                            ? _draft.voiceFileName
                            : '10–30 seconds, one speaker, no background noise.',
                        icon: Icons.audiotrack_rounded,
                        done: _draft.hasVoice,
                        onTap: _pickVoice,
                      ),
                      const SizedBox(height: 10),
                      _StepCard(
                        number: 3,
                        title: 'Give them a name',
                        subtitle: _draft.displayName == 'Familiar Person'
                            ? 'Like “Ammu”, “Bhaiya” or “Rifat”.'
                            : _draft.displayName,
                        icon: Icons.badge_outlined,
                        done: _draft.displayName != 'Familiar Person',
                        onTap: _editName,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'e.g. Rifat',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        onChanged: (value) => setState(() {
                          _draft = _draft.copyWith(
                            displayName: value.trim().isEmpty
                                ? 'Familiar Person'
                                : value.trim(),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (_cloning) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _progress < 0.4
                                        ? 'Analysing voice…'
                                        : _progress < 0.75
                                            ? 'Matching tone and rhythm…'
                                            : 'Building your companion…',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(_progress * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  minHeight: 7,
                                  backgroundColor: AppColors.pale,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.purple),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      GradientButton(
                        label: _draft.cloned
                            ? 'Rebuild voice profile'
                            : 'Create voice profile',
                        icon: Icons.graphic_eq_rounded,
                        loading: _cloning,
                        onPressed: ready ? _startClone : null,
                      ),
                      if (!_draft.hasVoice)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Upload a voice sample to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      if (_draft.cloned) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _testVoice,
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 18),
                                label: const Text('Test voice'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _startCall(state),
                                icon: const Icon(Icons.video_call_rounded,
                                    size: 18),
                                label: const Text('Call now'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.amberSoft.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.science_outlined,
                                size: 18, color: Color(0xFFB45309)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demo build: your photo and sample are stored on-device. A real clone requires Fish Audio, ElevenLabs or Hugging Face keys, with automatic fallback to on-device TTS.',
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

  Future<void> _pickPhoto() async {
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
        if (mounted) {
          AppUtils.showSnack(context, 'Photo is too large. Try a smaller one.',
              error: true);
        }
        return;
      }
      setState(() => _draft = _draft.copyWith(photoBase64: base64Encode(bytes)));
      if (mounted) {
        await context.read<AppState>().setVoiceProfile(_draft);
      }
    } catch (_) {
      if (mounted) {
        AppUtils.showSnack(context, 'Could not open the gallery.', error: true);
      }
    }
  }

  Future<void> _pickVoice() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.audio);
      if (file == null) return;
      setState(() => _draft = _draft.copyWith(
            voiceFileName: file.name,
            cloned: false,
          ));
      if (mounted) {
        await context.read<AppState>().setVoiceProfile(_draft);
      }
    } catch (_) {
      if (mounted) {
        AppUtils.showSnack(context, 'Could not open the file picker.',
            error: true);
      }
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _nameController.text);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name your companion'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Rifat'),
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
    if (value != null && value.trim().isNotEmpty) {
      _nameController.text = value.trim();
      setState(() => _draft = _draft.copyWith(displayName: value.trim()));
      if (mounted) {
        await context.read<AppState>().setVoiceProfile(_draft);
      }
    }
  }

  Future<void> _startClone() async {
    if (!_draft.hasVoice) return;
    setState(() {
      _cloning = true;
      _progress = 0;
    });
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress = (_progress + 0.025).clamp(0.0, 1.0);
      });
      if (_progress >= 1.0) {
        timer.cancel();
        _finishClone();
      }
    });
  }

  Future<void> _finishClone() async {
    setState(() {
      _cloning = false;
      _draft = _draft.copyWith(cloned: true);
    });
    await context.read<AppState>().setVoiceProfile(_draft);
    if (!mounted) return;
    AppUtils.showSnack(context, 'Voice profile ready. Try a test or start a call.');
  }

  Future<void> _testVoice() async {
    final name = _draft.displayName;
    await _tts.speak(
      'Hey, it\'s $name. I\'m here whenever you want to practise. Tell me about your day.',
    );
  }

  void _startCall(AppState state) {
    final scenario = Scenario(
      id: 'familiar-call',
      title: 'Catch up with ${_draft.displayName}',
      subtitle: 'A familiar face, a gentle chat',
      category: 'Everyday English',
      description:
          'Talk to someone familiar about your day, your worries, or something good that happened.',
      aiRole: 'A familiar person who knows you well',
      openingLine: 'Hey, it\'s me. Come on, tell me what happened today.',
      emoji: '💜',
      level: state.level,
      goals: const [
        'Speak from the heart',
        'Use one new word',
        'Ask a question back',
      ],
      colors: const [Color(0xFFF472B6), Color(0xFFDB2777)],
      personaId: 'custom',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          scenario: scenario,
          persona: state.customPersona,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    required this.onTap,
  });

  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: done ? AppColors.mintSoft : AppColors.pale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              size: 19,
              color: done ? AppColors.mintDeep : AppColors.purple,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $number',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.muted,
                  ),
                ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 19, color: AppColors.muted),
        ],
      ),
    );
  }
}
