/// VYRO AI â€” Onboarding Animations & Screen
/// Optimized for web: reduced sparkle count, smaller phone, lighter shadows.

import 'dart:math';
import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.accent = const Color(0xFF8855FF),
  });
}

const List<OnboardingPage> kOnboardingPages = [
  OnboardingPage(
    title: 'AI Video Generator',
    description: 'Turn ideas into cinematic videos with AI-powered text, image and script-to-video generation.',
    icon: Icons.play_circle,
    accent: Color(0xFF8855FF),
  ),
  OnboardingPage(
    title: 'AI Voice & Image',
    description: 'Generate realistic voiceovers and stunning images to bring your stories to life.',
    icon: Icons.mic,
    accent: Color(0xFF00D5FF),
  ),
  OnboardingPage(
    title: 'Pro Video Editor',
    description: 'Cut, merge, add audio and export social-ready reels with the built-in editor.',
    icon: Icons.edit,
    accent: Color(0xFFEC4899),
  ),
  OnboardingPage(
    title: 'Publish & Grow',
    description: 'Export in HD, add captions and share directly to Reels, TikTok and Shorts.',
    icon: Icons.share,
    accent: Color(0xFF10B981),
  ),
];

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.animation, this.sparkles);

  final Animation<double> animation;
  final List<_Sparkle> sparkles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final t = animation.value;
    for (final s in sparkles) {
      final phase = s.phase + t * s.speed;
      final x = s.cx + cos(phase) * s.orbit;
      final y = s.cy + sin(phase * 1.3) * s.orbit * 0.6;
      final alpha = (0.2 + 0.8 * (0.5 + 0.5 * sin(t * 4 + s.phase))).clamp(0.0, 1.0);
      paint.color = s.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), s.radius, paint);
      canvas.drawLine(
        Offset(x - s.radius, y),
        Offset(x + s.radius, y),
        paint..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(x, y - s.radius),
        Offset(x, y + s.radius),
        paint..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.animation != animation;
}

class _Sparkle {
  final Color color;
  final double cx, cy, orbit, radius, speed, phase;
  _Sparkle({
    required this.color,
    required this.cx,
    required this.cy,
    required this.orbit,
    required this.radius,
    required this.speed,
    required this.phase,
  });
}

final List<_Sparkle> _onboardingSparkles = _buildSparkles();

List<_Sparkle> _buildSparkles() {
  final r = Random(7);
  return List.generate(15, (i) { // Reduced from 30
    final hue = (i * 113.0) % 360;
    return _Sparkle(
      color: HSVColor.fromAHSV(0.7, hue.toDouble(), 1.0, 0.9).toColor(),
      cx: r.nextDouble(),
      cy: r.nextDouble(),
      orbit: 30 + r.nextDouble() * 100, // Reduced from 40+160
      radius: 1.5 + r.nextDouble() * 1.5, // Reduced from 2+3
      speed: 0.3 + r.nextDouble() * 0.5, // Reduced from 0.3+0.7
      phase: r.nextDouble() * 2 * pi,
    );
  });
}

class FloatingSmartphone extends StatefulWidget {
  final double size;
  const FloatingSmartphone({super.key, this.size = 200}); // Reduced from 260

  @override
  State<FloatingSmartphone> createState() => _FloatingSmartphoneState();
}

class _FloatingSmartphoneState extends State<FloatingSmartphone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _tiltCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5)) // Reduced from 4s
      ..repeat(reverse: true);
    _tiltCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6)) // Reduced from 7s
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _tiltCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 0.5, // Phone aspect is 200x400
      height: widget.size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatCtrl, _tiltCtrl]),
          builder: (context, child) {
            final floatY = sin(_floatCtrl.value * 2 * pi) * (widget.size / 400) * 8;
            final tiltX = _tiltCtrl.value * 0.08; // Reduced from 0.12
            final tiltY = _tiltCtrl.value * 0.05; // Reduced from 0.08
            return Transform.translate(
              offset: Offset(0, floatY),
              child: Transform(
                alignment: FractionalOffset.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(tiltX)
                  ..rotateY(tiltY),
                child: child,
              ),
            );
          },
          child: _Phone(),
        ),
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, // Reduced from 260
      height: 400, // Reduced from 520
      decoration: BoxDecoration(
        color: const Color(0xFF17243B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1), // Reduced
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000), // Reduced opacity
            blurRadius: 20, // Reduced from 40
            spreadRadius: 2, // Reduced from 4
          ),
          BoxShadow(
            color: Color(0x188B5CF6), // Reduced opacity
            blurRadius: 20, // Reduced from 40
            spreadRadius: 1, // Reduced from 2
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 18, // Reduced from 22
            width: 90, // Reduced from 110
            decoration: const BoxDecoration(
              color: Color(0xFF0B1220),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            margin: const EdgeInsets.only(top: 14),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFF0B1220),
                    child: const Center(
                      child: Icon(Icons.play_circle_fill, color: Color(0xFF8855FF), size: 44), // Reduced from 56
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '0:12 / 0:45',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AI Reels',
                        style: TextStyle(
                          color: Color(0xFF8855FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 26, // Reduced from 30
            width: 120, // Reduced from 140
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) => Container(
                width: 20, height: 4, // Reduced from 24x5
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i == 1 ? 0.7 : 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingThumbnails extends StatelessWidget {
  final Animation<double> animation;
  const FloatingThumbnails({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: RepaintBoundary( // Add RepaintBoundary
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = animation.value;
            return CustomPaint(
              size: Size.infinite,
              painter: _ThumbnailOrbitPainter(t),
            );
          },
        ),
      ),
    );
  }
}

class _ThumbnailOrbitPainter extends CustomPainter {
  _ThumbnailOrbitPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    final count = 4; // Reduced from 6
    final radius = 180.0; // Reduced from 260
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + t * 0.4; // Reduced speed
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius * 0.5;
      final scale = 0.6 + 0.2 * (0.5 + 0.5 * sin(t * 2 + i));
      final alpha = 0.5 + 0.3 * (0.5 + 0.5 * sin(t + i));
      paint.color = const Color(0xFF8855FF).withValues(alpha: alpha.clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 48, height: 72), // Reduced from 60x90
          const Radius.circular(10),
        ),
        paint..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 44, height: 68),
          const Radius.circular(8),
        ),
        paint..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.3),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbnailOrbitPainter old) => old.t != t;
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final double progress;
  const OnboardingPageWidget({super.key, required this.page, this.progress = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Transform.translate(
            offset: Offset(progress * -25, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              width: 90, // Reduced from 110
              height: 90,
              decoration: BoxDecoration(
                color: page.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: page.accent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: page.accent.withValues(alpha: 0.2), // Reduced opacity
                    blurRadius: 16, // Reduced from 24
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(page.icon, size: 40, color: page.accent), // Reduced from 48
            ),
          ),
          const SizedBox(height: 30),
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26, // Reduced from 30
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15, // Reduced from 17
              height: 1.5,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingIndicator extends StatelessWidget {
  final int current;
  final int total;
  const OnboardingIndicator({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: active ? 24 : 10,
          height: 6,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF8855FF) : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
