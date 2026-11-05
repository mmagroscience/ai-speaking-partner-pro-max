import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/talking_avatar.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;
  AppGoal? _goal;
  CefrLevel? _level;
  HelpLanguage _language = HelpLanguage.english;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _language = state.helpLanguage;
    _goal = state.onboarded ? state.goal : null;
    _level = state.onboarded ? state.level : null;
    if (state.name != 'Friend') _nameController.text = state.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _t(String en, String bn, String hi) => switch (_language) {
        HelpLanguage.english => en,
        HelpLanguage.bangla => bn,
        HelpLanguage.hindi => hi,
      };

  String _goalLabel(AppGoal goal) => switch (_language) {
        HelpLanguage.english => goal.label,
        HelpLanguage.bangla => goal.bnLabel,
        HelpLanguage.hindi => goal.hiLabel,
      };

  String _goalBlurb(AppGoal goal) => switch (_language) {
        HelpLanguage.english => goal.blurb,
        HelpLanguage.bangla => goal.bnBlurb,
        HelpLanguage.hindi => goal.blurb,
      };

  bool get _canContinue => switch (_step) {
        0 => _goal != null,
        1 => _level != null,
        _ => true,
      };

  void _next() {
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final state = context.read<AppState>();
    await state.completeOnboarding(
      selectedGoal: _goal ?? AppGoal.everydayEnglish,
      selectedLevel: _level ?? CefrLevel.beginner,
      selectedName: _nameController.text,
      language: _language,
    );
  }

  Future<void> _openLevelCheck() async {
    final result = await showModalBottomSheet<CefrLevel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _LevelCheckSheet(),
    );
    if (result != null && mounted) {
      setState(() => _level = result);
      AppUtils.showSnack(
        context,
        'Level set to ${result.label}. You can change it later.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: switch (_step) {
                      0 => _buildGoalsStep(),
                      1 => _buildLevelStep(),
                      _ => _buildReadyStep(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.bg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientButton(
                  label: _step == 2
                      ? _t('Start my first call', 'প্রথম কল শুরু করুন',
                          'मेरी पहली कॉल शुरू करें')
                      : _t('Continue', 'চালিয়ে যান', 'जारी रखें'),
                  icon: _step == 2
                      ? Icons.video_call_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: _canContinue ? _next : null,
                ),
                if (_step > 0)
                  TextButton(
                    onPressed: () => setState(() => _step -= 1),
                    child: Text(_t('Back', 'পেছনে', 'पीछे')),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              const AppLogo(size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Let\'s get you talking', 'চলুন কথা বলা শুরু করি',
                          'चलिए बोलना शुरू करें'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${_t('Step', 'ধাপ', 'चरण')} ${_step + 1} / 3',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<HelpLanguage>(
                initialValue: _language,
                onSelected: (value) => setState(() => _language = value),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (context) => HelpLanguage.values
                    .map(
                      (lang) => PopupMenuItem(
                        value: lang,
                        child: Text(lang.label),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate_rounded,
                          size: 15, color: AppColors.purple),
                      const SizedBox(width: 5),
                      Text(
                        _language == HelpLanguage.english
                            ? 'EN'
                            : _language == HelpLanguage.bangla
                                ? 'বাং'
                                : 'हि',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_step + 1) / 3,
              minHeight: 5,
              backgroundColor: AppColors.pale,
              valueColor: const AlwaysStoppedAnimation(AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          _t('What do you want to speak about?',
              'আপনি কোন বিষয়ে কথা বলতে চান?', 'आप किस बारे में बोलना चाहते हैं?'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'Choose one goal. Your coach will shape every call around it.',
            'একটি লক্ষ্য বেছে নিন। আপনার কোচ প্রতিটি কল সেভাবে সাজাবে।',
            'एक लक्ष्य चुनें। आपका कोच हर कॉल उसी तरह बनाएगा।',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AppGoal.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 164,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final goal = AppGoal.values[index];
            final selected = _goal == goal;
            return _GoalCard(
              goal: goal,
              label: _goalLabel(goal),
              blurb: _goalBlurb(goal),
              selected: selected,
              onTap: () => setState(() => _goal = goal),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLevelStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          _t('Where are you right now?',
              'এখন আপনি কোন স্তরে আছেন?', 'अभी आप किस स्तर पर हैं?'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'No judgement. This only changes how much support your coach gives you.',
            'কোনো বিচার নেই। এটি শুধু ঠিক করে আপনার কোচ কতটা সাহায্য করবে।',
            'कोई जजमेंट नहीं। यह सिर्फ तय करता है कि कोच कितनी मदद करेगा।',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        ...CefrLevel.values.map((level) {
          final selected = _level == level;
          final description = _language == HelpLanguage.bangla
              ? level.bnDescription
              : level.description;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: selected ? AppColors.pale : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? AppColors.purple : AppColors.line,
                  width: selected ? 1.8 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => setState(() => _level = level),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.purple
                              : AppColors.pale.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          level.icon,
                          color: selected ? Colors.white : AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  level.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Pill(
                                  label: level.band,
                                  color: AppColors.mintDeep,
                                  background: AppColors.mintSoft,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? AppColors.purple : AppColors.line,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 2),
        Center(
          child: TextButton.icon(
            onPressed: _openLevelCheck,
            icon: const Icon(Icons.quiz_outlined, size: 18),
            label: Text(
              _t('Not sure? Take a 2-minute level check',
                  'নিশ্চিত নন? ২ মিনিটের লেভেল টেস্ট দিন',
                  'पक्का नहीं? 2 मिनट का लेवल टेस्ट दें'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyStep() {
    final goal = _goal ?? AppGoal.everydayEnglish;
    final level = _level ?? CefrLevel.beginner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          _t('You\'re all set', 'সব প্রস্তুত', 'सब तैयार है'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'One last thing — what should your coach call you?',
            'শেষ একটি কথা — আপনার কোচ আপনাকে কী নামে ডাকবে?',
            'आखिरी बात — आपका कोच आपको किस नाम से बुलाए?',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: _t('Your name', 'আপনার নাম', 'आपका नाम'),
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  const TalkingAvatar(
                    persona: Persona(
                      id: 'sarah',
                      name: 'Sarah',
                      role: 'Friendly Tutor',
                      accent: 'US Accent',
                      tagline: '',
                      greeting: '',
                      emoji: 'S',
                      colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                    ),
                    size: 74,
                    showRings: false,
                    statusText: 'Online',
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meet Sarah, your coach',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t(
                            'She will call you face-to-face, listen carefully, and never rush you.',
                            'তিনি আপনার সাথে মুখোমুখি ভিডিও কলে কথা বলবেন, মন দিয়ে শুনবেন — কখনো তাড়াহুড়ো করবেন না।',
                            'वह आपसे फेस-टू-फेस कॉल पर बात करेंगी, ध्यान से सुनेंगी और कभी जल्दी नहीं करेंगी।',
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      icon: goal.icon,
                      label: _goalLabel(goal),
                      caption: _t('Your goal', 'আপনার লক্ষ্য', 'आपका लक्ष्य'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      icon: level.icon,
                      label: level.label,
                      caption: level.band,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mintSoft.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.translate_rounded,
                  size: 20, color: AppColors.mintDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t(
                    'Speak English or Bangla. Tap the BN mic in a call and Sarah will understand you.',
                    'ইংরেজি বা বাংলা — যেভাবে স্বাচ্ছন্দ্য, বলুন। কলে BN মাইক চাপলে সারাহ বাংলাও বুঝবে।',
                    'अंग्रेज़ी या बांग्ला — जैसे सहज हों, बोलें। कॉल में BN माइक दबाएँ।',
                  ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.mintDeep,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.label,
    required this.blurb,
    required this.selected,
    required this.onTap,
  });

  final AppGoal goal;
  final String label;
  final String blurb;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? AppColors.pale : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? AppColors.purple : AppColors.line,
          width: selected ? 1.8 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.purple : AppColors.pale,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      goal.icon,
                      size: 20,
                      color: selected ? Colors.white : AppColors.purple,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: selected ? 1 : 0,
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  blurb,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    height: 1.35,
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  caption,
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
    );
  }
}

class _LevelCheckSheet extends StatefulWidget {
  const _LevelCheckSheet();

  @override
  State<_LevelCheckSheet> createState() => _LevelCheckSheetState();
}

class _LevelCheckSheetState extends State<_LevelCheckSheet> {
  final List<int?> _answers = List<int?>.filled(3, null);
  bool _showResult = false;

  static const _questions = [
    (
      question: 'She ___ to work every day.',
      options: ['go', 'goes', 'went'],
      correct: 1,
    ),
    (
      question: 'If I had more time, I ___ travel more.',
      options: ['will', 'would', 'would have'],
      correct: 1,
    ),
    (
      question: 'The report ___ by the team yesterday.',
      options: ['completed', 'was completed', 'has completed'],
      correct: 1,
    ),
  ];

  int get _score {
    var total = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correct) total++;
    }
    return total;
  }

  CefrLevel get _level {
    if (_score >= 3) return CefrLevel.advanced;
    if (_score >= 2) return CefrLevel.intermediate;
    return CefrLevel.beginner;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
        child: _showResult ? _buildResult() : _buildQuiz(),
      ),
    );
  }

  Widget _buildQuiz() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2-minute level check',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Answer three quick questions. There is no timer and no score shared with anyone.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        ...List.generate(_questions.length, (index) {
          final item = _questions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${item.question}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(item.options.length, (optionIndex) {
                  final selected = _answers[index] == optionIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _answers[index] = optionIndex),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.pale : AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.purple
                                : AppColors.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 17,
                              color: selected
                                  ? AppColors.purple
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              item.options[optionIndex],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        GradientButton(
          label: 'See my level',
          icon: Icons.insights_rounded,
          onPressed: _answers.every((a) => a != null)
              ? () => setState(() => _showResult = true)
              : null,
        ),
      ],
    );
  }

  Widget _buildResult() {
    final level = _level;
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.mintGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.mint.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 14),
        Text('You scored $_score / 3',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Based on this quick check, ${level.label} is a comfortable starting point.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Pill(
          label: '${level.label} • ${level.band}',
          icon: level.icon,
          color: AppColors.purple,
          fontSize: 12,
        ),
        const SizedBox(height: 22),
        GradientButton(
          label: 'Use ${level.label}',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => Navigator.pop(context, level),
        ),
        TextButton(
          onPressed: () => setState(() => _showResult = false),
          child: const Text('Review my answers'),
        ),
      ],
    );
  }
}
