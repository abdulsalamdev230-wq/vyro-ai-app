/// VYRO AI â€” Reusable UI Widgets


import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../core/animations/dashboard_animations.dart' show RippleContainer;

// ---------- Gradient text ----------

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;
  const GradientText({
    super.key,
    required this.text,
    this.style = const TextStyle(),
    this.colors = const [Color(0xFF8855FF), Color(0xFF00D5FF)],
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
      ).createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

// ---------- Glassmorphism card ----------

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  final bool neon;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = VyroBorderRadius.cardLg,
    this.color = VyroColors.surfaceCard,
    this.neon = true,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: vyroGlassCardDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return RippleContainer(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: card,
    );
  }
}

// ---------- Neon border card ----------

class NeonCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final List<Color> colors;
  final EdgeInsetsGeometry padding;
  const NeonCard({
    super.key,
    required this.child,
    this.borderRadius = VyroBorderRadius.cardLg,
    this.colors = const [Color(0xFF8855FF), Color(0xFF00D5FF)],
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: vyroNeonBorderDecoration(
        borderRadius: borderRadius,
        colors: colors,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: VyroColors.surfaceCard.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

// ---------- Section header ----------

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: VyroTypography.headlineSmall.copyWith(
                  color: VyroColors.textWhite,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: VyroTypography.bodyMedium.copyWith(
                    color: VyroColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(color: Color(0xFF8855FF), fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- Honest unavailable state ----------

class UnavailableState extends StatelessWidget {
  final String title;
  final String message;
  final String? setupHint;
  final VoidCallback? onConfigure;
  final IconData icon;
  const UnavailableState({
    super.key,
    this.title = 'Provider not configured',
    this.message = 'This feature requires an API key that has not been set up.',
    this.setupHint,
    this.onConfigure,
    this.icon = Icons.build,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          neon: false,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: VyroColors.textDim, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: VyroTypography.headlineSmall.copyWith(
                  color: VyroColors.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: VyroTypography.bodyMedium.copyWith(
                  color: VyroColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              if (setupHint != null) ...[
                const SizedBox(height: 12),
                Text(
                  setupHint!,
                  style: VyroTypography.captionMedium.copyWith(
                    color: VyroColors.textDim,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              if (onConfigure != null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(onPressed: onConfigure, child: const Text('Configure API Key')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Shimmer loading card ----------

class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerCard({
    super.key,
    this.width = double.infinity,
    this.height = 160,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: VyroColors.surfaceInput,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Shimmer(
        gradient: LinearGradient(
          colors: [Color(0xFF141829), Color(0xFF2A3048), Color(0xFF141829)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFF263750),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    );
  }
}
