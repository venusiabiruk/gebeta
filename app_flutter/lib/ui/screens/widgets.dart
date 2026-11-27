import 'package:flutter/material.dart';

import 'palette.dart';

/// True when the player asked the phone to reduce motion.
bool reduceMotion(BuildContext context) {
  return MediaQuery.of(context).disableAnimations;
}

/// Warm wood background used by every screen.
class WoodBackground extends StatelessWidget {
  const WoodBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.2),
          radius: 1.6,
          colors: [
            GebetaColors.woodLight,
            GebetaColors.woodMid,
            GebetaColors.woodDark,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}

/// Moves its child slowly up and down. It stands still when motion is reduced.
class Bob extends StatefulWidget {
  const Bob({super.key, required this.child});

  final Widget child;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final lift = Curves.easeInOut.transform(_controller.value) * -8;
        return Transform.translate(offset: Offset(0, lift), child: child);
      },
    );
  }
}

/// A soft light that sweeps across its child every few seconds.
/// It stands still (no light at all) when motion is reduced.
class Shine extends StatefulWidget {
  const Shine({super.key, required this.child, this.radius = 28});

  final Widget child;
  final double radius;

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // The light sweeps during the first third of each cycle,
                  // then it rests until the next cycle.
                  if (_controller.value > 0.35) {
                    return const SizedBox.shrink();
                  }
                  final t = _controller.value / 0.35;
                  return Align(
                    alignment: Alignment(-1.6 + 3.2 * t, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.3,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0x66FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill button: gold and filled when primary, gold outline otherwise.
/// A primary button can also get the shine animation.
class GButton extends StatelessWidget {
  const GButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.primary = false,
    this.shine = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool shine;

  static const TextStyle _text = TextStyle(
    fontFamily: 'Baloo2',
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

  @override
  Widget build(BuildContext context) {
    if (primary) {
      final button = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: GebetaColors.gold,
          foregroundColor: GebetaColors.ink,
          minimumSize: const Size(0, 56),
          shape: const StadiumBorder(),
          textStyle: _text,
        ),
        onPressed: onPressed,
        child: Text(label),
      );
      if (shine) {
        return Shine(child: button);
      }
      return button;
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: GebetaColors.cream,
        side: const BorderSide(color: GebetaColors.gold, width: 2),
        minimumSize: const Size(0, 56),
        shape: const StadiumBorder(),
        textStyle: _text,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Translucent dark panel with a gold-brown border.
class GPanel extends StatelessWidget {
  const GPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GebetaColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x99FFC878), width: 2),
      ),
      child: child,
    );
  }
}

/// Top bar with a round back button and a centered title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}
