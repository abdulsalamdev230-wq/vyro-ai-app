/// VYRO AI — Shared Authentication Widgets
///
/// Common building blocks used by the dedicated Login and Register screens:
/// official brand icons (Google "G", Facebook circle-f), centered social
/// buttons, styled inputs, the brand illustration panel and the responsive
/// split-screen shell. One source of truth for both pages.

import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'branding.dart';

// ============================================================================
// OFFICIAL GOOGLE "G" ICON (vector, official 48x48 geometry + palette)
// ============================================================================

class GoogleGIcon extends StatelessWidget {
  const GoogleGIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 48;
    canvas.save();
    canvas.translate(
      (size.width - 48 * scale) / 2,
      (size.height - 48 * scale) / 2,
    );
    canvas.scale(scale);

    // Red — top arc
    final red = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
      ..close();

    // Blue — right side + horizontal bar
    final blue = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
      ..lineTo(24, 20)
      ..lineTo(24, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();

    // Yellow — left side
    final yellow = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24)
      ..cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
      ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();

    // Green — bottom arc
    final green = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
      ..close();

    final fill = Paint()..style = PaintingStyle.fill;
    canvas.drawPath(red, fill..color = const Color(0xFFEA4335));
    canvas.drawPath(blue, fill..color = const Color(0xFF4285F4));
    canvas.drawPath(yellow, fill..color = const Color(0xFFFBBC05));
    canvas.drawPath(green, fill..color = const Color(0xFF34A853));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// OFFICIAL FACEBOOK ICON — blue circle with white "f"
// ============================================================================

class FacebookFIcon extends StatelessWidget {
  const FacebookFIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FacebookFPainter()),
    );
  }
}

class _FacebookFPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    // Official Facebook blue circle.
    canvas.drawCircle(
      center,
      s / 2,
      Paint()..color = const Color(0xFF1877F2),
    );

    // White "f" glyph, scaled to ~55% of the circle and centered.
    final f = Path()
      ..moveTo(18, 2)
      ..lineTo(15, 2)
      ..arcToPoint(
        const Offset(10, 7),
        radius: const Radius.circular(5),
        clockwise: false,
      )
      ..lineTo(10, 10)
      ..lineTo(7, 10)
      ..lineTo(7, 14)
      ..lineTo(10, 14)
      ..lineTo(10, 22)
      ..lineTo(14, 22)
      ..lineTo(14, 14)
      ..lineTo(17, 14)
      ..lineTo(18, 10)
      ..lineTo(14, 10)
      ..lineTo(14, 7)
      ..arcToPoint(const Offset(15, 6), radius: const Radius.circular(1))
      ..lineTo(18, 6)
      ..close();

    final bounds = f.getBounds();
    final scale = (s * 0.55) / bounds.height;
    canvas.save();
    canvas.translate(
      center.dx - bounds.center.dx * scale,
      center.dy - bounds.center.dy * scale,
    );
    canvas.scale(scale);
    canvas.drawPath(f, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// SOCIAL BUTTON — icon + label group perfectly centered
// ============================================================================

class AuthSocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final bool enabled;
  final VoidCallback onPressed;

  const AuthSocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? textColor : textColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRIMARY CTA + GHOST BUTTON
// ============================================================================

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: VyroColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'Inter',
                ),
              ),
      ),
    );
  }
}

class AuthGhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool enabled;

  const AuthGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF94A3B8),
          side: const BorderSide(color: Color(0xFF334155)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF64748B), size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// INPUT FIELD + MESSAGE BOX
// ============================================================================

class AuthInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AuthInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon, color: const Color(0xFF64748B), size: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF64748B),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF101B35),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF263750)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: VyroColors.primaryPurple,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthMessage extends StatelessWidget {
  final String? message;
  const AuthMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BRAND PANEL (left side illustration, desktop)
// ============================================================================

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VyroLogo(size: 72, borderRadius: 18),
        const SizedBox(height: 8),
        const VyroWordmark(fontSize: 22, letterSpacing: 1),
        const SizedBox(height: 28),
        const Text(
          'Bring Your Stories to Life.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Create magical 3D animated stories with the power of AI.',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 220,
          child: CustomPaint(
            size: Size.infinite,
            painter: _HuskyIllustrationPainter(),
          ),
        ),
        const SizedBox(height: 40),
        const AuthFeatureHighlight(
          icon: Icons.auto_stories_outlined,
          title: 'AI Story Creation',
          subtitle: 'Turn ideas into cinematic narratives instantly.',
        ),
        const SizedBox(height: 20),
        const AuthFeatureHighlight(
          icon: Icons.animation_outlined,
          title: 'Cinematic 3D Animation',
          subtitle: 'Professional-grade 3D visuals in seconds.',
        ),
        const SizedBox(height: 20),
        const AuthFeatureHighlight(
          icon: Icons.volume_up_outlined,
          title: 'Multilingual AI Voices',
          subtitle: 'Narrate your stories in any language.',
        ),
        const SizedBox(height: 40),
        const Text(
          'VYRO AI',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class AuthFeatureHighlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthFeatureHighlight({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: VyroColors.primaryPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: VyroColors.primaryPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: VyroColors.primaryPurpleLight, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HuskyIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8855FF).withValues(alpha: 0.15),
          const Color(0xFF00D5FF).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45));
    canvas.drawCircle(center, size.width * 0.45, glowPaint);

    final hillPaint = Paint()..color = const Color(0xFF0D1420);
    final hillPath = Path();
    hillPath.moveTo(0, size.height * 0.75);
    hillPath.lineTo(size.width * 0.2, size.height * 0.85);
    hillPath.lineTo(size.width * 0.35, size.height * 0.7);
    hillPath.lineTo(size.width * 0.5, size.height * 0.82);
    hillPath.lineTo(size.width * 0.65, size.height * 0.72);
    hillPath.lineTo(size.width * 0.8, size.height * 0.88);
    hillPath.lineTo(size.width, size.height * 0.78);
    hillPath.lineTo(size.width, size.height);
    hillPath.lineTo(0, size.height);
    hillPath.close();
    canvas.drawPath(hillPath, hillPaint);

    final moonPaint = Paint()
      ..color = const Color(0xFFF5F3E4).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.22), 14, moonPaint);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final stars = [
      Offset(size.width * 0.15, size.height * 0.18),
      Offset(size.width * 0.35, size.height * 0.12),
      Offset(size.width * 0.55, size.height * 0.25),
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.25, size.height * 0.32),
    ];
    for (final star in stars) {
      canvas.drawCircle(star, 2, starPaint);
    }

    final headCenter = Offset(size.width * 0.42, size.height * 0.48);
    final headRadius = size.width * 0.13;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawCircle(
      Offset(headCenter.dx + 6, headCenter.dy + 6),
      headRadius,
      shadowPaint,
    );

    final headPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE2E8F0),
          const Color(0xFF94A3B8),
        ],
      ).createShader(
        Rect.fromCircle(center: headCenter, radius: headRadius),
      );
    canvas.drawCircle(headCenter, headRadius, headPaint);

    final earPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx - 24, headCenter.dy - 30),
          width: 22,
          height: 40,
        ),
        Radius.circular(8),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx + 24, headCenter.dy - 30),
          width: 22,
          height: 40,
        ),
        Radius.circular(8),
      ),
      earPaint,
    );

    final eyePatchPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(headCenter.dx - 14, headCenter.dy - 6), 9, eyePatchPaint);
    canvas.drawCircle(Offset(headCenter.dx + 14, headCenter.dy - 6), 9, eyePatchPaint);

    final eyePaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF00D5FF), const Color(0xFF0284C7)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(headCenter.dx - 14, headCenter.dy - 6),
          radius: 5,
        ),
      );
    canvas.drawCircle(Offset(headCenter.dx - 14, headCenter.dy - 6), 5, eyePaint);
    canvas.drawCircle(Offset(headCenter.dx + 14, headCenter.dy - 6), 5, eyePaint);

    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(headCenter.dx - 16, headCenter.dy - 8), 1.5, highlightPaint);
    canvas.drawCircle(Offset(headCenter.dx + 12, headCenter.dy - 8), 1.5, highlightPaint);

    final nosePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(headCenter.dx, headCenter.dy + 12), 6, nosePaint);

    final mouthPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + 24),
        width: 16,
        height: 10,
      ),
      0.2,
      2.7,
      false,
      mouthPaint,
    );

    final backpackPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx + 4, headCenter.dy + 42),
          width: 34,
          height: 30,
        ),
        Radius.circular(10),
      ),
      backpackPaint,
    );

    final backpackHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx - 2, headCenter.dy + 38),
          width: 14,
          height: 20,
        ),
        Radius.circular(6),
      ),
      backpackHighlight,
    );

    final treePaint = Paint()..color = const Color(0xFF0F172A);
    _drawTree(canvas, Offset(size.width * 0.08, size.height * 0.78), 34, treePaint);
    _drawTree(canvas, Offset(size.width * 0.92, size.height * 0.82), 38, treePaint);
    _drawTree(canvas, Offset(size.width * 0.25, size.height * 0.85), 28, treePaint);
    _drawTree(canvas, Offset(size.width * 0.75, size.height * 0.88), 32, treePaint);

    final groundGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8855FF).withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      groundGlow,
    );
  }

  void _drawTree(Canvas canvas, Offset center, double height, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - height);
    path.lineTo(center.dx - height * 0.35, center.dy);
    path.lineTo(center.dx + height * 0.35, center.dy);
    path.close();
    canvas.drawPath(path, paint);

    final trunkPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - height * 0.1),
        width: 6,
        height: height * 0.15,
      ),
      trunkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// SPLIT-SCREEN SHELL — responsive scaffold used by both pages
// ============================================================================

class AuthPageShell extends StatelessWidget {
  final Widget formPanel;

  const AuthPageShell({super.key, required this.formPanel});

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = MediaQuery.of(context).size.width > 900;

    final background = Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A101C),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A101C), Color(0xFF0D1420)],
        ),
      ),
    );

    final leftPanel = Container(
      constraints: const BoxConstraints(minWidth: 320),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(child: const AuthBrandPanel()),
    );

    final rightPanel = Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(child: formPanel),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      body: Stack(
        children: [
          background,
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: isTabletOrDesktop
                  ? Row(
                      children: [
                        Expanded(flex: 1, child: leftPanel),
                        Container(
                          width: 1,
                          height: double.infinity,
                          color: const Color(0xFF17243B),
                        ),
                        Expanded(flex: 1, child: rightPanel),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          leftPanel,
                          const SizedBox(height: 1),
                          rightPanel,
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SOCIAL BUTTON GROUP — Google / Facebook / Apple on both pages
// ============================================================================

class SocialButtonsBlock extends StatelessWidget {
  final bool enabled;
  final void Function(String provider) onProvider;
  final String orLabel;

  const SocialButtonsBlock({
    super.key,
    required this.enabled,
    required this.onProvider,
    required this.orLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthSocialButton(
          icon: const GoogleGIcon(),
          label: 'Continue with Google',
          backgroundColor: const Color(0xFF101B35),
          textColor: Colors.white,
          borderColor: const Color(0xFF334155),
          enabled: enabled,
          onPressed: () => onProvider('google'),
        ),
        const SizedBox(height: 12),
        AuthSocialButton(
          icon: const FacebookFIcon(),
          label: 'Continue with Facebook',
          backgroundColor: const Color(0xFF101B35),
          textColor: Colors.white,
          borderColor: const Color(0xFF334155),
          enabled: enabled,
          onPressed: () => onProvider('facebook'),
        ),
        const SizedBox(height: 12),
        AuthSocialButton(
          icon: const Icon(Icons.apple, color: Colors.white, size: 22),
          label: 'Continue with Apple',
          backgroundColor: const Color(0xFF101B35),
          textColor: Colors.white,
          borderColor: const Color(0xFF334155),
          enabled: enabled,
          onPressed: () => onProvider('apple'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFF263750))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                orLabel,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFF263750))),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
