import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/scenario_card.dart';
import '../call/incoming_call_screen.dart';
import 'ielts_screen.dart';
import 'pronunciation_screen.dart';
import 'vocabulary_screen.dart';
import 'voice_clone_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'For you';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scenarios = _filteredScenarios(state);

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 112),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Practice your world',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Pick a real-life moment and step into it.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  UserAvatar(
                    base64: state.avatarBase64,
                    name: state.firstName,
                    size: 44,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search a topic or situation…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'For you',
                      selected: _filter == 'For you',
                      onTap: () => setState(() => _filter = 'For you'),
                    ),
                    ...CefrLevel.values.map(
                      (level) => _FilterChip(
                        label: level.label,
                        selected: _filter == level.label,
                        onTap: () => setState(() => _filter = level.label),
                      ),
                    ),
                    ...Catalog.categories.skip(1).map(
                          (category) => _FilterChip(
                            label: category,
                            selected: _filter == category,
                            onTap: () => setState(() => _filter = category),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '${scenarios.length} scenario${scenarios.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.sort_rounded,
                      size: 14, color: AppColors.muted),
                  const SizedBox(width: 3),
                  const Text(
                    'For you',
                    style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              if (scenarios.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No scenario found',
                  message:
                      'Try another word or choose “For you” to see every practice scene.',
                )
              else
                ...scenarios.map(
                  (scenario) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ScenarioCard(
                      scenario: scenario,
                      persona: state.personaFor(scenario),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncomingCallScreen(
                            scenario: scenario,
                            persona: state.personaFor(scenario),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Skill labs',
                subtitle: 'Target one skill at a time',
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.28,
                children: [
                  _SkillCard(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Pronunciation Lab',
                    subtitle: 'Word-by-word colouring',
                    colors: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PronunciationScreen(),
                      ),
                    ),
                  ),
                  _SkillCard(
                    icon: Icons.workspace_premium_rounded,
                    title: 'IELTS Examiner',
                    subtitle: 'Part 1, 2, 3 + band',
                    colors: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IeltsScreen()),
                    ),
                  ),
                  _SkillCard(
                    icon: Icons.auto_stories_rounded,
                    title: '3-Tone Vocabulary',
                    subtitle: 'Casual, formal, native',
                    colors: const [Color(0xFF34D399), Color(0xFF059669)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VocabularyScreen(),
                      ),
                    ),
                  ),
                  _SkillCard(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Voice Lab',
                    subtitle: 'Clone a familiar voice',
                    colors: const [Color(0xFFF472B6), Color(0xFFDB2777)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VoiceCloneScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        color: AppColors.mintDeep, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Every scenario is unlimited. Repeat it as many times as you need — the AI never runs out of patience.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.45,
                          color: AppColors.mintDeep.withValues(alpha: 0.9),
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
    );
  }

  List<Scenario> _filteredScenarios(AppState state) {
    var list = state.allScenarios;
    if (_filter != 'For you') {
      final level = CefrLevel.values.where((l) => l.label == _filter);
      if (level.isNotEmpty) {
        list = list.where((s) => s.level == level.first).toList();
      } else {
        list = list.where((s) => s.category == _filter).toList();
      }
    }
    if (_query.isNotEmpty) {
      final query = _query.toLowerCase();
      list = list.where((s) {
        final persona = state.personaFor(s);
        return s.title.toLowerCase().contains(query) ||
            s.subtitle.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            s.category.toLowerCase().contains(query) ||
            persona.name.toLowerCase().contains(query);
      }).toList();
    }
    return list;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Material(
        color: selected ? AppColors.purple : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.purple : AppColors.line,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: AppColors.deep.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
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
      ),
    );
  }
}
