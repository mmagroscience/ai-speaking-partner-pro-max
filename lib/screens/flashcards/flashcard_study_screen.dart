import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/flashcard_models.dart';
import '../../services/flashcard_service.dart';
import '../../services/tts_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

// Palette copied from the reference flashcard design: near-black page, dark
// grey card, blue labels, white illustration panel and tinted chips.
const _pageTop = Color(0xFF080B12);
const _pageBottom = Color(0xFF11151F);
const _cardTop = Color(0xFF212329);
const _cardBottom = Color(0xFF181A20);
const _cardLine = Color(0xFF31343D);
const _blue = Color(0xFF4C9AFF);
const _bodyText = Color(0xFFE7E9F0);
const _subtle = Color(0xFF9AA0B0);
const _panelInk = Color(0xFF14171F);

const _defBg = Color(0xFF14304A);
const _defLine = Color(0xFF2D5D83);

const _greenBg = Color(0xFF16301F);
const _greenLine = Color(0xFF2C5B3B);
const _greenText = Color(0xFF7FD8A0);

const _redBg = Color(0xFF331C21);
const _redLine = Color(0xFF5C2C35);
const _redText = Color(0xFFF2909C);

const _purpleBg = Color(0xFF2E1E3B);
const _purpleLine = Color(0xFF4E3468);
const _purpleText = Color(0xFFC9A9F5);

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

  void _flip() {
    _cardKey.currentState?.flip();
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
      return const _StudyBackground(
        child: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }
    if (_finished) return _buildSummary(context);
    final card = _current;
    if (card == null) return _buildSummary(context);

    final state = context.watch<AppState>();
    final fraction = _deck.isEmpty ? 0.0 : _index / _deck.length;

    return _StudyBackground(
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
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Flashcards',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '${_level.label} • ${_level.bnLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9.5, color: _subtle),
                        ),
                      ],
                    ),
                  ),
                  _KnownPill(count: state.flashKnown.length),
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
                      color: _subtle,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_knownCount known · $_againCount again',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _subtle,
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
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(_blue),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            icon: Icons.arrow_back_rounded,
            label: 'Review again',
            color: const Color(0xFFFF8A3D),
            onTap: _again,
          ),
          _ControlButton(
            icon: Icons.touch_app_rounded,
            label: 'See meaning',
            color: const Color(0xFF37C9C9),
            onTap: _flip,
            primary: true,
          ),
          _ControlButton(
            icon: Icons.arrow_forward_rounded,
            label: 'I know it',
            color: _greenText,
            onTap: _gotIt,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final state = context.watch<AppState>();
    return _StudyBackground(
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
                    color: Colors.white,
                    background: Colors.white.withValues(alpha: 0.10),
                    fontSize: 9.5,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _level.colors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _level.colors.last.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _deck.isEmpty ? 'No cards yet' : 'Deck complete!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _deck.isEmpty
                    ? 'This level has no cards to show.'
                    : '${_level.label} • ${_deck.length} cards reviewed',
                style: const TextStyle(fontSize: 12, color: _subtle),
              ),
              const SizedBox(height: 18),
              _Panel(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _SummaryStat(
                      emoji: '✅',
                      value: '$_knownCount',
                      label: 'known',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    _SummaryStat(
                      emoji: '🔁',
                      value: '$_againCount',
                      label: 'again',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    _SummaryStat(
                      emoji: '🃏',
                      value: '${_deck.length}',
                      label: 'cards',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFC24B),
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
                          color: _subtle,
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.75),
                ),
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
              color: Colors.white,
              height: 1.1,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 9.5, color: _subtle)),
        ],
      ),
    );
  }
}

class _StudyBackground extends StatelessWidget {
  const _StudyBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_pageTop, _pageBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -110,
            child: _Glow(size: 340, color: Color(0xFF1E5AA8)),
          ),
          Positioned(
            bottom: -170,
            left: -130,
            child: _Glow(size: 360, color: Color(0xFF17375F)),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _KnownPill extends StatelessWidget {
  const _KnownPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _greenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _greenLine),
      ),
      child: Text(
        '✓ $count known',
        style: const TextStyle(
          color: _greenText,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
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
      color: Colors.white.withValues(alpha: 0.07),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: Colors.white),
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
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final size = primary ? 58.0 : 48.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: primary
              ? color.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.06),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary
                      ? color.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.10),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: color, size: primary ? 26 : 22),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.95),
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
  final GlobalKey<_FlipCardState> _flipKey = GlobalKey<_FlipCardState>();
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

  void flip() {
    _flipKey.currentState?.toggle();
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
              key: _flipKey,
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

  @override
  void didUpdateWidget(covariant _FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The flip controller is reused between cards, so make sure every new word
    // starts on its front face.
    if (oldWidget.card.key != widget.card.key) {
      _controller.value = 0;
    }
  }

  void toggle() {
    if (_controller.value < 0.5) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggle,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      card.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 33,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.7,
                        height: 1.12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isKnown)
                  const Padding(
                    padding: EdgeInsets.only(right: 6, top: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: _greenText,
                    ),
                  ),
                _GlassIcon(icon: Icons.volume_up_rounded, onTap: onSpeak),
              ],
            ),
            if (card.ipa.isNotEmpty) ...[
              const SizedBox(height: 9),
              _IpaPill(ipa: card.ipa),
            ],
            if (card.isBaby) ...[
              const SizedBox(height: 6),
              Text(
                card.bangla,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _IllustrationPanel(card: card, level: level),
            ),
            const SizedBox(height: 12),
            _FactRow(
              label: 'Part of Speech:',
              value: card.type.isEmpty ? 'word' : card.type,
            ),
            const SizedBox(height: 8),
            _FactRow(label: 'Level:', value: card.levelLabel, accent: true),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 12,
                    color: _subtle.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to see the meaning',
                    style: TextStyle(
                      color: _subtle.withValues(alpha: 0.85),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IpaPill extends StatelessWidget {
  const _IpaPill({required this.ipa});

  final String ipa;

  @override
  Widget build(BuildContext context) {
    final value = ipa.startsWith('/') ? ipa : '/$ipa/';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D35),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Color(0xFFE6E8EF),
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({required this.card, required this.level});

  final Flashcard card;
  final StudyLevel level;

  @override
  Widget build(BuildContext context) {
    final caption = card.isBaby
        ? 'FIRST WORDS'
        : '${card.type.isEmpty ? 'WORD' : card.type.toUpperCase()} · ${card.levelLabel}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math
              .min(constraints.maxHeight * 0.72, constraints.maxWidth * 0.62)
              .clamp(60.0, 210.0)
              .toDouble();
          return Column(
            children: [
              Text(
                card.word.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _panelInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Center(
                  child: _PanelArt(
                    emoji: card.illustration,
                    size: size,
                    tint: level.colors.last,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(height: 1, color: const Color(0xFFE3E6EF)),
              const SizedBox(height: 7),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7183),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PanelArt extends StatefulWidget {
  const _PanelArt({
    required this.emoji,
    required this.size,
    required this.tint,
  });

  final String emoji;
  final double size;
  final Color tint;

  @override
  State<_PanelArt> createState() => _PanelArtState();
}

class _PanelArtState extends State<_PanelArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
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
          offset: Offset(0, -5 + value * 10),
          child: Transform.scale(scale: 0.98 + value * 0.04, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.tint.withValues(alpha: 0.20),
              widget.tint.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Center(
          child: Text(
            widget.emoji,
            style: TextStyle(fontSize: widget.size * 0.62, height: 1),
          ),
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _blue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accent ? _greenBg : const Color(0xFF32343C),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: accent
                    ? _greenLine
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent ? _greenText : const Color(0xFFE9EBF2),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({required this.card, required this.onSpeak});

  final Flashcard card;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -34,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.055,
                child: Text(
                  card.illustration,
                  style: const TextStyle(fontSize: 200, height: 1),
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
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (card.ipa.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                card.ipa.startsWith('/')
                                    ? card.ipa
                                    : '/${card.ipa}/',
                                style: const TextStyle(
                                  color: _subtle,
                                  fontSize: 11.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _GlassIcon(icon: Icons.volume_up_rounded, onTap: onSpeak),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (card.type.isNotEmpty)
                      _MiniTag(label: card.type, color: _blue),
                    if (!card.isBaby)
                      _MiniTag(
                        label: 'CEFR ${card.levelLabel}',
                        color: _greenText,
                      ),
                    _MiniTag(
                      label: card.isBaby ? 'First words' : 'Oxford 3000',
                      color: _purpleText,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (card.isBaby) ...[
                                    const _SectionTitle(
                                      emoji: '📘',
                                      label: 'Bangla meaning',
                                      first: true,
                                    ),
                                    _DefBox(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            card.bangla,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            card.babySentence,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.75,
                                              ),
                                              fontSize: 12.5,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (card.senses.isNotEmpty) ...[
                                    _SectionTitle(
                                      emoji: '📄',
                                      label: 'Definition',
                                      first: card.isBaby,
                                    ),
                                    _DefBox(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (
                                            var i = 0;
                                            i < card.senses.length;
                                            i++
                                          )
                                            _SenseBlock(
                                              index: i + 1,
                                              total: card.senses.length,
                                              sense: card.senses[i],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (card.examples.isNotEmpty) ...[
                                    const _SectionTitle(
                                      emoji: '✏️',
                                      label: 'Example',
                                    ),
                                    _ExampleBox(values: card.examples),
                                  ],
                                  if (card.synonyms.isNotEmpty) ...[
                                    const _SectionTitle(
                                      emoji: '🧬',
                                      label: 'Synonyms & Similar',
                                    ),
                                    _ChipWrap(
                                      values: card.synonyms,
                                      background: _greenBg,
                                      line: _greenLine,
                                      text: _greenText,
                                    ),
                                  ],
                                  if (card.antonyms.isNotEmpty) ...[
                                    const _SectionTitle(
                                      emoji: '🔀',
                                      label: 'Antonyms & Opposites',
                                    ),
                                    _ChipWrap(
                                      values: card.antonyms,
                                      background: _redBg,
                                      line: _redLine,
                                      text: _redText,
                                    ),
                                  ],
                                  if (card.phrases.isNotEmpty) ...[
                                    const _SectionTitle(
                                      emoji: '💬',
                                      label: 'Common Phrases',
                                    ),
                                    _ChipWrap(
                                      values: card.phrases,
                                      background: _purpleBg,
                                      line: _purpleLine,
                                      text: _purpleText,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              _SpeakPrompt(card: card),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Swipe right if you know it · left to review',
                    style: TextStyle(
                      fontSize: 9,
                      color: _subtle.withValues(alpha: 0.8),
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.emoji,
    required this.label,
    this.first = false,
  });

  final String emoji;
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 14, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _blue,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefBox extends StatelessWidget {
  const _DefBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _defBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _defLine),
      ),
      child: child,
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
      padding: EdgeInsets.only(bottom: index == total ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (total > 1)
                Text(
                  '($index) ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Expanded(
                child: Text(
                  sense.definition,
                  style: const TextStyle(
                    color: _bodyText,
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExampleBox extends StatelessWidget {
  const _ExampleBox({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < values.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == values.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(top: 2, right: 9),
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '“${values[i]}”',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
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

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.values,
    required this.background,
    required this.line,
    required this.text,
  });

  final List<String> values;
  final Color background;
  final Color line;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: line),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  value,
                  style: TextStyle(
                    color: text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpeakPrompt extends StatelessWidget {
  const _SpeakPrompt({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mic_rounded, size: 16, color: _blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              card.isBaby
                  ? 'Say “${card.word}” out loud, then use it in a sentence.'
                  : 'Your turn: say a sentence with “${card.word}” out loud.',
              style: const TextStyle(
                color: _subtle,
                fontSize: 11,
                height: 1.45,
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _cardLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: child,
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
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      ),
    );
  }
}
