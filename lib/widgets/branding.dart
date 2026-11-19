/// VYRO AI — Reusable branding widgets
///
/// Single source of truth for the official "Vyro AI Neon Orbital" logo and
/// wordmark so every screen (splash, login, register, auth panels) shows the
/// exact same brand mark, colors and typography.
import 'package:flutter/material.dart';

/// The official Vyro AI logo asset path (launcher icon source image).
const String kVyroLogoAsset = 'assets/icon/vyro_icon.png';

/// Official brand colors — violet + electric blue, matching the logo.
const Color kVyroViolet = Color(0xFF8855FF);
const Color kVyroBlue = Color(0xFF00D5FF);

/// The Vyro AI Neon Orbital logo, rendered from the original asset with an
/// optional purple/blue glow. Never repaints or recolors the artwork.
class VyroLogo extends StatelessWidget {
  final double size;
  final bool glow;
  final double borderRadius;

  const VyroLogo({
    super.key,
    this.size = 96,
    this.glow = true,
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        kVyroLogoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );

    if (!glow) return image;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: kVyroViolet.withValues(alpha: 0.45),
            blurRadius: size * 0.42,
            spreadRadius: size * 0.05,
            offset: const Offset(-4, 0),
          ),
          BoxShadow(
            color: kVyroBlue.withValues(alpha: 0.40),
            blurRadius: size * 0.42,
            spreadRadius: size * 0.05,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: image,
    );
  }
}

/// The "Vyro AI" gradient wordmark used beside and below the logo.
class VyroWordmark extends StatelessWidget {
  final double fontSize;
  final double letterSpacing;

  const VyroWordmark({
    super.key,
    this.fontSize = 40,
    this.letterSpacing = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Vyro AI',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: letterSpacing,
        fontFamily: 'Inter',
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [Colors.white, Color(0xFFD9C8FF), kVyroBlue],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromLTWH(0, 0, fontSize * 4.4, fontSize * 1.2)),
      ),
    );
  }
}

/// Logo + wordmark stacked vertically — used on splash and auth headers.
class VyroBrandBlock extends StatelessWidget {
  final double logoSize;
  final double wordmarkSize;
  final String? tagline;
  final double gap;

  const VyroBrandBlock({
    super.key,
    this.logoSize = 110,
    this.wordmarkSize = 38,
    this.tagline,
    this.gap = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VyroLogo(size: logoSize),
        SizedBox(height: gap),
        VyroWordmark(fontSize: wordmarkSize),
        if (tagline != null) ...[
          const SizedBox(height: 10),
          Text(
            tagline!,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }
}
