/// VYRO AI — Button Interaction Animations
///
/// Scale animation, ripple effects, glow effects and loading animations for
/// buttons. Performance-friendly: uses implicit animations and avoids
/// rebuilding heavy subtrees.


import 'package:flutter/material.dart';

// ---------- Scale-on-press button wrapper ----------

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool enabled;
  final double scaleDown;
  const ScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.enabled = true,
    this.scaleDown = 0.94,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: widget.enabled && _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------- Glow button (neon pulse while pressed / active) ----------

class GlowButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color glowColor;
  final bool active;
  const GlowButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.glowColor = const Color(0xFF8855FF),
    this.active = false,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showGlow = widget.active || _pressed;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final blur = showGlow ? (12.0 + 8.0 * _pulse.value) : 0.0;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: 0.35 + 0.25 * _pulse.value),
                        blurRadius: blur,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onPressed,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ---------- Loading spinner button ----------

class LoadingButton extends StatefulWidget {
  final Widget child;
  final bool loading;
  final VoidCallback? onPressed;
  final Color color;
  const LoadingButton({
    super.key,
    required this.child,
    this.loading = false,
    this.onPressed,
    this.color = const Color(0xFF8855FF),
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }
  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.loading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: widget.loading
          ? SizedBox(
              height: 20,
              width: 20,
              child: RotatingLoader(color: Colors.white, controller: _spin),
            )
          : widget.child,
    );
  }
}

class RotatingLoader extends AnimatedWidget {
  final Color color;
  RotatingLoader({super.key, required this.color, required AnimationController controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Transform.rotate(
      angle: animation.value * 2 * 3.141592653589793,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

// ---------- Pulse indicator dot (e.g. "recording", "processing") ----------

class PulseDot extends AnimatedWidget {
  final Color color;
  final double size;
  PulseDot({super.key, this.color = const Color(0xFFEF4444), this.size = 10,
    required AnimationController controller}) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final alpha = 0.5 + 0.5 * animation.value;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3 * alpha),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ---------- Ripple fill button (material ripple with neon tint) ----------

class RippleFillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color baseColor;
  final bool enabled;
  const RippleFillButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.baseColor = const Color(0xFF8855FF),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onPressed : null,
        highlightColor: baseColor.withValues(alpha: 0.2),
        splashColor: baseColor.withValues(alpha: 0.35),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: enabled ? baseColor : const Color(0xFF263750),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

