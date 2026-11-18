import 'package:flutter/material.dart';

import 'palette.dart';
import 'routes.dart';
import 'widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // TODO(U2): replace this delay with the real loading (SettingsStore, AiService.init).
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WoodBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gebeta',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 88,
                      color: GebetaColors.gold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The traditional Ethiopian seed game',
                style: TextStyle(fontSize: 20, color: GebetaColors.cream),
              ),
              const SizedBox(height: 28),
              Container(
                width: 240,
                height: 8,
                decoration: BoxDecoration(
                  color: GebetaColors.panel,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.05, end: 1),
                  duration: const Duration(milliseconds: 1800),
                  builder: (context, value, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: GebetaColors.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
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
