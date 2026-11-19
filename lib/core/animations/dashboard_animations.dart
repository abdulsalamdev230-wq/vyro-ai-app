/// VYRO AI — Dashboard Animations
/// Optimized for web: reduced animation speeds, lighter shadows, RepaintBoundary.

import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF0B1220), const Color(0xFF0E1626), t)!,
                  Color.lerp(const Color(0xFF0A101C), const Color(0xFF0D1420), t)!,
                  const Color(0xFF0B1220),
                ],
              ),
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class FloatingAIOrb extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  const FloatingAIOrb({super.key, this.size = 100, this.onTap});

  @override
  State<FloatingAIOrb> createState() => _FloatingAIOrbState();
}

class _FloatingAIOrbState extends State<FloatingAIOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatCtrl, _pulseCtrl]),
        builder: (context, child) {
          final y = sin(_floatCtrl.value * 2 * pi) * 8;
          final pulse = 1.0 + 0.04 * sin(_pulseCtrl.value * 2 * pi);
          return Transform.translate(
            offset: Offset(0, y),
            child: Transform.scale(
              scale: pulse,
              child: GestureDetector(
                onTap: widget.onTap,
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF8855FF), Color(0xFF00D5FF), Color(0xFF0A101C)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x208B5CF6),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}

class CardEntrance extends StatelessWidget {
  final Widget child;
  final double delay;
  const CardEntrance({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class NeonButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? glowColor;
  final bool enabled;
  const NeonButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.glowColor,
    this.enabled = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? const Color(0xFF8855FF);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(
          _pressed && widget.enabled ? 0.95 : 1.0,
          _pressed && widget.enabled ? 0.95 : 1.0,
          1.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.enabled
                  ? [glow, glow.withValues(alpha: 0.7)]
                  : [const Color(0xFF263750), const Color(0xFF263750)],
            ),
            boxShadow: widget.enabled && _pressed
                ? [
                    BoxShadow(
                      color: glow.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class RippleContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  const RippleContainer({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        highlightColor: const Color(0xFF8855FF).withValues(alpha: 0.1),
        splashColor: const Color(0xFF00D5FF).withValues(alpha: 0.15),
        child: child,
      ),
    );
  }
}

class SmoothBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  const SmoothBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<SmoothBottomNav> createState() => _SmoothBottomNavState();
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.color = const Color(0xFF8855FF),
  });
}

class _SmoothBottomNavState extends State<SmoothBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _slideCtrl.value = widget.currentIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant SmoothBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _slideCtrl.animateTo(widget.currentIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF0A101C),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(widget.items.length, (i) {
            final item = widget.items[i];
            final active = i == widget.currentIndex;
            final activeProgress = Tween<double>(begin: i.toDouble(), end: i.toDouble()).animate(_slideCtrl);
            final isActive = activeProgress.value.round() == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? item.color.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? item.color : const Color(0xFF64748B),
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive ? item.color : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
