import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/flashcard_models.dart';
import '../../services/flashcard_service.dart';
import '../../services/tts_service.dart';
import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

const _cardTop = Color(0xFF271848);
const _cardBottom = Color(0xFF140D26);

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({super.key, required this.level});

  final StudyLevel level;

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  final TtsService _tts = TtsService();
  final GlobalKey<_SwipeCardState> _cardKey = GlobalKey<_SwipeCardState>();
  final Set<String> _reQueued = {};

  List<Flashcard> _deck = [];
  bool _loading = true;
  bool _finished = false;
  int _index = 0;
  int _knownCount = 0;
  int _againCount = 0;
  int _seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;

  StudyLevel get _level => widget.level;

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _loadDeck() async {
    final state = context.read<AppState>();
    final all = await FlashcardService.load();
    var deck = FlashcardService.buildDeck(
      all,
      _level,
      state.flashSeen,
      state.flashKnown,
      seed: _seed,
    );
    if (deck.isEmpty) {
      deck = FlashcardService.poolFor(
        all,
        _level,
        seed: _seed,
      ).take(FlashcardService.deckSize).toList();
    }
    if (!mounted) return;
    setState(() {
      _deck = deck;
      _loading = false;
      _finished = deck.isEmpty;
      _index = 0;
      _knownCount = 0;
      _againCount = 0;
      _reQueued.clear();
    });
  }

  void _speak(Flashcard card) {
    _tts.speak(card.speechText());
  }

  void _onSwipe(Flashcard card, bool known) {
    final state = context.read<AppState>();
    state.markFlashSeen(card.word);
    if (known) {
      state.setFlashKnown(card.word, true);
      _knownCount += 1;
    } else {
      _againCount += 1;
      if (_reQueued.add(card.key)) {
        _deck = [..._deck, card];
      }
    }
    setState(() {
      _index += 1;
      _finished = _index >= _deck.length;
    });
    if (_index >= _deck.length) {
      state.completeFlashDeck();
    }
  }

  void _again() {
    final card = _current;
    if (card == null) return;
    _cardKey.currentState?.swipeOut(false);
  }

  void _gotIt() {
    final card = _current;
    if (card == null) return;
    _cardKey.currentState?.swipeOut(true);
  }

  Flashcard? get _current =>
      _index >= 0 && _index < _deck.length ? _deck[_index] : null;

  void _restart() {
    _seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    setState(() => _loading = true);
    _loadDeck();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppBackground(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
      );
    }
    if (_finished) return _buildSummary(context);
    final card = _current;
    if (card == null) return _buildSummary(context);

    final state = context.watch<AppState>();
    final fraction = _deck.isEmpty ? 0.0 : _index / _deck.length;

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 16, 4),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _level.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${_level.bnLabel} • ${_level.stage}',
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
                  Pill(
                    label: '✓ ${state.flashKnown.length} known',
                    color: AppColors.mintDeep,
                    background: AppColors.mintSoft,
                    fontSize: 9,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Card ${_index + 1} of ${_deck.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_knownCount known · $_againCount again',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation(_level.colors.last),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 470,
                    maxHeight: 600,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: _SwipeCard(
                      key: _cardKey,
                      card: card,
                      level: _level,
                      isKnown: state.isFlashKnown(card.word),
                      onSpeak: () => _speak(card),
                      onSwipe: (known) => _onSwipe(card, known),
                    ),
                  ),
                ),
              ),
            ),
            _buildControls(),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Text(
                'Tap the card to flip • Swipe left to review again',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 9.5,
                  color: AppColors.muted.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 8, 34, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            icon: Icons.replay_rounded,
            label: 'Again',
            color: AppColors.amber,
            onTap: _again,
          ),
          GestureDetector(
            onTap: () {
              final card = _current;
              if (card != null) _speak(card);
            },
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
          _ControlButton(
            icon: Icons.check_rounded,
            label: 'Got it',
            color: AppColors.mint,
            onTap: _gotIt,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final state = context.watch<AppState>();
    return AppBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Pill(
                    label: _level.label,
                    color: _level.colors.last,
                    background: _level.colors.first.withValues(alpha: 0.15),
                    fontSize: 9.5,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _level.colors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _level.colors.last.withValues(alpha: 0.32),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _deck.isEmpty ? 'No cards yet' : 'Deck complete!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _deck.isEmpty
                    ? 'This level has no cards to show.'
                    : '${_level.label} • ${_deck.length} cards reviewed',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _SummaryStat(
                      emoji: '✅',
                      value: '$_knownCount',
                      label: 'known',
                    ),
                    Container(width: 1, height: 36, color: AppColors.line),
                    _SummaryStat(
                      emoji: '🔁',
                      value: '$_againCount',
                      label: 'again',
                    ),
                    Container(width: 1, height: 36, color: AppColors.line),
                    _SummaryStat(
                      emoji: '🃏',
                      value: '${_deck.length}',
                      label: 'cards',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.amber,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.flashKnown.isEmpty
                            ? 'Tap a card, listen to the word, then swipe right when you know it.'
                            : 'You now know ${state.flashKnown.length} words. '
                                  '${state.flashDecks} decks finished so far.',
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              GradientButton(
                label: 'Study another deck',
                icon: Icons.refresh_rounded,
                height: 52,
                gradient: LinearGradient(colors: _level.colors),
                onPressed: _restart,
              ),
              const SizedBox(height: 9),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to levels'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SwipeCard extends StatefulWidget {
  const _SwipeCard({
    super.key,
    required this.card,
    required this.level,
    required this.isKnown,
    required this.onSpeak,
    required this.onSwipe,
  });

  final Flashcard card;
  final StudyLevel level;
  final bool isKnown;
  final VoidCallback onSpeak;
  final ValueChanged<bool> onSwipe;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard>
    with SingleTickerProviderStateMixin {
  double _dx = 0;
  bool _dragging = false;
  bool _exiting = false;

  @override
  void didUpdateWidget(covariant _SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The GlobalKey keeps this State alive across cards, so reset the swipe
    // offset and exit flag whenever a new word arrives.
    if (oldWidget.card.key != widget.card.key) {
      _dx = 0;
      _dragging = false;
      _exiting = false;
    }
  }

  void swipeOut(bool known) {
    if (_exiting) return;
    setState(() {
      _exiting = true;
      _dragging = false;
      _dx = known ? 720 : -720;
    });
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      if (mounted) widget.onSwipe(known);
    });
  }

  void _endDrag(DragEndDetails details) {
    if (_exiting) return;
    final velocity = details.primaryVelocity ?? 0;
    final right = _dx > 80 || velocity > 700;
    final left = _dx < -80 || velocity < -700;
    setState(() => _dragging = false);
    if (right) {
      swipeOut(true);
    } else if (left) {
      swipeOut(false);
    } else {
      setState(() => _dx = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final duration = _dragging
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final opacity = (1 - (_dx.abs() / 900)).clamp(0.55, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        if (_exiting) return;
        setState(() => _dragging = true);
      },
      onHorizontalDragUpdate: (details) {
        if (_exiting) return;
        setState(() => _dx += details.delta.dx);
      },
      onHorizontalDragEnd: _endDrag,
      onHorizontalDragCancel: () {
        if (_exiting) return;
        setState(() {
          _dragging = false;
          _dx = 0;
        });
      },
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _dx),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(value, value.abs() * 0.02),
                child: Transform.rotate(
                  angle: value / math.max(width, 320) * 0.16,
                  child: Opacity(opacity: opacity, child: child),
                ),
              );
            },
            child: _FlipCard(
              key: ValueKey(widget.card.key),
              card: widget.card,
              level: widget.level,
              isKnown: widget.isKnown,
              onSpeak: widget.onSpeak,
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: const Alignment(-0.72, -0.18),
              child: _Stamp(
                label: 'AGAIN',
                color: AppColors.amber,
                visible: _dx < -30,
                angle: -0.18,
              ),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: const Alignment(0.72, -0.18),
              child: _Stamp(
                label: 'GOT IT',
                color: AppColors.mint,
                visible: _dx > 30,
                angle: 0.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.color,
    required this.visible,
    required this.angle,
  });

  final String label;
  final Color color;
  final bool visible;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 120),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(9),
            color: color.withValues(alpha: 0.94),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({
    super.key,
    required this.card,
    required this.level,
    required this.isKnown,
    required this.onSpeak,
  });

  final Flashcard card;
  final StudyLevel level;
  final bool isKnown;
  final VoidCallback onSpeak;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.value < 0.5) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _BackFace(
                      card: widget.card,
                      level: widget.level,
                      onSpeak: widget.onSpeak,
                    ),
                  )
                : _FrontFace(
                    card: widget.card,
                    level: widget.level,
                    isKnown: widget.isKnown,
                    onSpeak: widget.onSpeak,
                  ),
          );
        },
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  const _FrontFace({
    required this.card,
    required this.level,
    required this.isKnown,
    required this.onSpeak,
  });

  final Flashcard card;
  final StudyLevel level;
  final bool isKnown;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final art = constraints.maxHeight < 400 ? 92.0 : 122.0;
          return Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        level.colors.last.withValues(alpha: 0.4),
                        level.colors.last.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            card.isBaby
                                ? 'FIRST WORDS'
                                : 'OXFORD 3000 · ${card.levelLabel}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isKnown)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AppColors.mint.withValues(alpha: 0.9),
                            ),
                          ),
                        _GlassIcon(
                          icon: Icons.volume_up_rounded,
                          onTap: onSpeak,
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (card.ipa.isNotEmpty)
                      Text(
                        card.ipa,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 13,
                          letterSpacing: 0.4,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          card.word,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    if (card.isBaby) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.bangla,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                    ],
                    const Spacer(),
                    _FloatingArt(emoji: card.illustration, size: art),
                    const Spacer(),
                    if (card.isBaby)
                      Text(
                        card.babySentence,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      )
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Tag(label: card.type.isEmpty ? 'word' : card.type),
                          _Tag(
                            label: card.levelLabel,
                            color: level.colors.first,
                          ),
                          _Tag(
                            label:
                                '${card.senses.length} meaning${card.senses.length == 1 ? '' : 's'}',
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to flip',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({
    required this.card,
    required this.level,
    required this.onSpeak,
  });

  final Flashcard card;
  final StudyLevel level;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Stack(
        children: [
          Positioned(
            right: -34,
            bottom: -40,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.06,
                child: Text(
                  card.illustration,
                  style: const TextStyle(fontSize: 210, height: 1),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (card.ipa.isNotEmpty)
                            Text(
                              card.ipa,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _GlassIcon(icon: Icons.volume_up_rounded, onTap: onSpeak),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    if (card.type.isNotEmpty) _Tag(label: card.type),
                    if (card.cefr.isNotEmpty && !card.isBaby)
                      _Tag(label: 'CEFR ${card.levelLabel}'),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (card.isBaby) ...[
                          Text(
                            card.bangla,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.babySentence,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                        ...card.senses.asMap().entries.map(
                          (entry) => _SenseBlock(
                            index: entry.key + 1,
                            total: card.senses.length,
                            sense: entry.value,
                          ),
                        ),
                        if (card.synonyms.isNotEmpty)
                          _ChipSection(
                            title: 'SYNONYMS',
                            values: card.synonyms,
                            color: AppColors.mint,
                          ),
                        if (card.antonyms.isNotEmpty)
                          _ChipSection(
                            title: 'ANTONYMS',
                            values: card.antonyms,
                            color: AppColors.rose,
                          ),
                        if (card.phrases.isNotEmpty)
                          _PhraseSection(phrases: card.phrases),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.mic_rounded,
                                size: 15,
                                color: AppColors.lavender,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  card.isBaby
                                      ? 'Say “${card.word}” out loud, then use it in a sentence.'
                                      : 'Your turn: say a sentence with “${card.word}” out loud.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10.5,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (card.senses.isEmpty &&
                            card.synonyms.isEmpty &&
                            card.phrases.isEmpty)
                          Text(
                            'Listen, repeat and use this word in your own sentence.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11.5,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Swipe right if you know it · left to review',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SenseBlock extends StatelessWidget {
  const _SenseBlock({
    required this.index,
    required this.total,
    required this.sense,
  });

  final int index;
  final int total;
  final FlashSense sense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (total > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 1, right: 6),
                  child: Text(
                    '$index.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  sense.definition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (sense.example.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(9),
                border: Border(
                  left: BorderSide(
                    color: AppColors.lavender.withValues(alpha: 0.6),
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                sense.example,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.values,
    required this.color,
  });

  final String title;
  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: values
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PhraseSection extends StatelessWidget {
  const _PhraseSection({required this.phrases});

  final List<String> phrases;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMON PHRASES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          ...phrases.map(
            (phrase) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.circle,
                      size: 3.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      phrase,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardTop, _cardBottom],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deep.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: color == null ? 0.1 : 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color == null
              ? Colors.white.withValues(alpha: 0.72)
              : Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _FloatingArt extends StatefulWidget {
  const _FloatingArt({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  State<_FloatingArt> createState() => _FloatingArtState();
}

class _FloatingArtState extends State<_FloatingArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -7 + value * 14),
          child: Transform.scale(scale: 1 + value * 0.03, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.14),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.lavender.withValues(alpha: 0.22),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.emoji,
            style: TextStyle(fontSize: widget.size * 0.5, height: 1),
          ),
        ),
      ),
    );
  }
}
