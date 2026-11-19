/// VYRO AI â€” Onboarding Screen
///
/// Page-based onboarding with 3D floating smartphone, floating thumbnails,
/// AI sparkles, page transitions and parallax effects.


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/routes.dart';
import '../../core/animations/onboarding_animation.dart';
import '../../core/animations/button_animations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vyro.seenOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      body: Stack(
        children: [
          // Decorative floating elements (parallax with page)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pageCtrl,
              builder: (context, child) {
                final t = (_pageCtrl.page ?? 0) / (kOnboardingPages.length - 1);
                return FloatingThumbnails(animation: AlwaysStoppedAnimation(t));
              },
            ),
          ),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: kOnboardingPages.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, i) {
                    final page = kOnboardingPages[i];
                    final pagePercent = (_pageCtrl.page ?? 0) - i;
                    final progress = (1 - pagePercent.abs().clamp(0, 1));
                    return OnboardingPageWidget(page: page, progress: progress.clamp(0.0, 1.0).toDouble());
                  },
                ),
              ),
              // Indicator (+ floating smartphone on last page)
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnboardingIndicator(current: _current, total: kOnboardingPages.length),
                    const SizedBox(height: 10),
                    // Small floating phone behind CTA on last page
                    if (_current == kOnboardingPages.length - 1)
                      const FloatingSmartphone(size: 130),
                  ],
                ),
              ),
              // CTA
              Padding(
                padding: const EdgeInsets.all(28),
                child: ScaleButton(
                  enabled: true,
                  onPressed: _current == kOnboardingPages.length - 1 ? _finish : () {
                    _pageCtrl.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8855FF), Color(0xFF00D5FF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x408B5CF6),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _current == kOnboardingPages.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _current == kOnboardingPages.length - 1
                              ? Icons.arrow_forward
                              : Icons.chevron_right,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
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
