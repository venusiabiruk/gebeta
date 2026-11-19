import 'package:flutter/material.dart';

import 'palette.dart';

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

/// Pill button: gold and filled when primary, gold outline otherwise.
class GButton extends StatelessWidget {
  const GButton(this.label, {super.key, required this.onPressed, this.primary = false});

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  static const TextStyle _text = TextStyle(
    fontFamily: 'Baloo2',
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton(
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
  const GPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

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
