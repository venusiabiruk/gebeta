import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/settings_state.dart';
import '../../state/providers.dart';
import 'palette.dart';
import 'routes.dart';
import 'widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Start the AI service and show the splash for at least 1.5 seconds.
  /// If the AI fails to load, the app still works (Master falls back to minimax).
  Future<void> _load() async {
    final minimumTime =
        Future<void>.delayed(const Duration(milliseconds: 1500));
    try {
      await ref.read(aiServiceProvider).init();
    } catch (e) {
      debugPrint(
          'AiService.init failed, the app goes on without the network: $e');
    }
    try {
      await ref.read(settingsProvider.notifier).load();
    } catch (e) {
      debugPrint('Settings failed to load, the defaults are used: $e');
    }
    await minimumTime;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final barTime = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 1500);
    return Scaffold(
      body: WoodBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Bob(
                child: Text(
                  'Gebeta',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 88,
                        color: GebetaColors.gold,
                      ),
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
                  duration: barTime,
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
