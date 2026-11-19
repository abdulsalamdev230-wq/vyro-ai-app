/// VYRO AI â€” AI Generation Animations
///
/// Animated neural network, rotating processing ring, progress indicator,
/// live job status and success/error animations.


import 'dart:math';
import 'package:flutter/material.dart';

// ---------- Neural network background painter ----------

class NeuralNetworkPainter extends CustomPainter {
  NeuralNetworkPainter(this.animation);

  final Animation<double> animation;
  final List<_Neuron> _neurons = [];
  final List<_Connection> _connections = [];

  NeuralNetworkPainter.withSeed(this.animation, int seed) {
    final r = Random(seed);
    for (int i = 0; i < 12; i++) {
      _neurons.add(_Neuron(
        x: r.nextDouble(),
        y: r.nextDouble(),
        speed: 0.02 + r.nextDouble() * 0.06,
        phase: r.nextDouble() * 2 * pi,
      ));
    }
    for (int i = 0; i < _neurons.length; i++) {
      for (int j = i + 1; j < _neurons.length; j++) {
        if (r.nextDouble() < 0.35) {
          _connections.add(_Connection(i, j));
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final paint = Paint();
    final nodes = _neurons.map((n) {
      final angle = t * n.speed + n.phase;
      final ox = cos(angle) * 0.03;
      final oy = sin(angle * 1.2) * 0.03;
      return Offset((n.x + ox) * size.width, (n.y + oy) * size.height);
    }).toList();

    // Draw connections
    for (final c in _connections) {
      final a = nodes[c.a];
      final b = nodes[c.b];
      final dist = (a - b).distance;
      if (dist < 220) {
        final alpha = (1 - dist / 220).clamp(0.0, 1.0);
        paint.color = const Color(0xFF8855FF).withValues(alpha: alpha * 0.5);
        paint.strokeWidth = 1.2;
        canvas.drawLine(a, b, paint);
      }
    }

    // Draw neurons
    for (int i = 0; i < nodes.length; i++) {
      final pulse = 0.5 + 0.5 * sin(t * 3 + _neurons[i].phase);
      paint.color = const Color(0xFF00D5FF).withValues(alpha: (0.4 + 0.6 * pulse).clamp(0, 1));
      canvas.drawCircle(nodes[i], 3 + pulse * 2, paint);
      // glow
      paint.color = const Color(0xFF8855FF).withValues(alpha: (0.15 * pulse).clamp(0, 1));
      canvas.drawCircle(nodes[i], 6 + pulse * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant NeuralNetworkPainter old) => old.animation != animation;
}

class _Neuron {
  final double x, y, speed, phase;
  _Neuron({required this.x, required this.y, required this.speed, required this.phase});
}

class _Connection {
  final int a, b;
  _Connection(this.a, this.b);
}

// ---------- Rotating processing ring ----------

class ProcessingRing extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  const ProcessingRing({
    super.key,
    this.size = 64,
    this.strokeWidth = 4,
    this.color = const Color(0xFF8855FF),
  });

  @override
  State<ProcessingRing> createState() => _ProcessingRingState();
}

class _ProcessingRingState extends State<ProcessingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.rotate(
          angle: _ctrl.value * 2 * pi,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: null,
              strokeWidth: widget.strokeWidth,
              color: widget.color,
              backgroundColor: widget.color.withValues(alpha: 0.15),
            ),
          ),
        );
      },
    );
  }
}

// ---------- Progress indicator with pulsing text ----------

class GenerationProgress extends StatelessWidget {
  final int percent; // 0..100
  final String status;
  const GenerationProgress({super.key, required this.percent, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 7,
                color: const Color(0xFF8855FF),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          status,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 15,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------- Success / error animation ----------

class JobResultAnimation extends StatelessWidget {
  final bool success;
  final String title;
  final String subtitle;
  final VoidCallback? onDismiss;
  const JobResultAnimation({
    super.key,
    required this.success,
    required this.title,
    required this.subtitle,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF17243B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: (success ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                .withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (success ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                  .withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (success ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            if (onDismiss != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  child: const Text('DONE'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
