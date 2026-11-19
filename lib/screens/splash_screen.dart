/// VYRO AI — Splash Screen (dedicated)
///
/// Premium branded launch: animated gradient, glowing logo mark that scales
/// in, gradient VYRO AI wordmark, tagline, and a subtle progress bar.
/// Routes based on auth state and whether onboarding has been seen.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../config/app_config.dart';
import '../widgets/branding.dart';
import '../../core/animations/dashboard_animations.dart'
    show AnimatedGradientBackground;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _routing = false;
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(curved);
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );
    _progress = Tween<double>(begin: 0.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Bootstrap (config + Firebase + persisted auth restore) was already run
    // in main() before runApp, so this is instant — the UI keeps playing the
    // branded intro animation while we wait. Routing happens once bootstrap
    // is confirmed AND the splash has played its minimum branded duration,
    // so a cold start never lingers and a warm start never flashes.
    final stopwatch = Stopwatch()..start();
    try {
      await _bootstrap();
    } catch (_) {
      // Bootstrap failure must never trap the user on the splash screen;
      // _route() below still resolves the correct destination.
    }
    const minSplash = Duration(milliseconds: 1700);
    final remaining = minSplash - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    if (mounted) _route();
  }

  Future<void> _bootstrap() async {
    await loadAppConfig();
    await AuthProvider.instance.initialize();
  }

  Future<void> _route() async {
    if (_routing) return;
    _routing = true;

    // Safety: never route before the auth state is known (prevents a brief
    // flicker to the login screen when the session is still being restored).
    final auth = AuthProvider.instance;
    if (!auth.isInitialized) {
      await auth.initialize();
    }

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('vyro.seenOnboarding') ?? false;
    final isSignedIn = auth.isSignedIn;

    if (!mounted) return;
    if (!seenOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    } else if (isSignedIn) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      body: AnimatedGradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing logo mark that scales in.
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: const VyroLogo(size: 116),
                ),
              ),
              const SizedBox(height: 28),
              // Gradient wordmark (brand widget).
              FadeTransition(
                opacity: _textOpacity,
                child: const VyroWordmark(fontSize: 40, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _taglineOpacity,
                child: const Text(
                  'Create. Animate. Inspire.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Subtle progress bar (deterministic, no fake spin).
              SizedBox(
                width: 180,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 3,
                        backgroundColor: const Color(0xFF263750),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF8855FF)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
