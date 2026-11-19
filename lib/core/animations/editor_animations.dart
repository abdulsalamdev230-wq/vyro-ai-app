/// VYRO AI — Editor Animations
///
/// Animated timeline, smooth clip movement, animated playhead, transition
/// previews and interactive sliders for the video editor.


import 'package:flutter/material.dart';

/// A clip placed on the timeline.
class TimelineClip {
  final String id;
  final String title;
  final double start; // seconds
  final double duration; // seconds
  final Color color;
  TimelineClip({
    required this.id,
    required this.title,
    required this.start,
    required this.duration,
    this.color = const Color(0xFF8855FF),
  });
}

/// Animated timeline with draggable clips and a moving playhead.
class AnimatedTimeline extends StatefulWidget {
  final List<TimelineClip> clips;
  final double durationSeconds; // total timeline length
  final double width; // pixel width of timeline
  final ValueChanged<double> onPlayheadChanged;
  final ValueChanged<TimelineClip>? onClipMoved;
  final double playheadPosition;
  const AnimatedTimeline({
    super.key,
    required this.clips,
    required this.durationSeconds,
    required this.width,
    required this.onPlayheadChanged,
    this.onClipMoved,
    this.playheadPosition = 0,
  });

  @override
  State<AnimatedTimeline> createState() => _AnimatedTimelineState();
}

class _AnimatedTimelineState extends State<AnimatedTimeline> {
  double _dragOffset = 0;
  TimelineClip? _dragging;

  double _positionToSeconds(double px) => (px / widget.width) * widget.durationSeconds;
  double _secondsToPosition(double seconds) => (seconds / widget.durationSeconds) * widget.width;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time ruler
        SizedBox(
          width: widget.width,
          height: 24,
          child: CustomPaint(
            painter: _TimelineRulerPainter(widget.durationSeconds, widget.width),
          ),
        ),
        // Track + clips + playhead
        SizedBox(
          width: widget.width,
          height: 120,
          child: Stack(
            children: [
              // Track lane
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF101B35),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Clips
              ...widget.clips.map((clip) {
                final left = _secondsToPosition(clip.start);
                final w = _secondsToPosition(clip.duration);
                return Positioned(
                  left: left,
                  top: 24,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _dragOffset += details.delta.dx;
                      });
                    },
                    onPanEnd: (_) {
                      if (_dragging == clip) {
                        final newStart = _positionToSeconds(
                          _secondsToPosition(clip.start) + _dragOffset,
                        ).clamp(0.0, widget.durationSeconds - clip.duration);
                        widget.onClipMoved?.call(TimelineClip(
                          id: clip.id,
                          title: clip.title,
                          start: newStart,
                          duration: clip.duration,
                          color: clip.color,
                        ));
                        _dragging = null;
                        _dragOffset = 0;
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: w.clamp(40, double.infinity),
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [clip.color, clip.color.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: clip.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          clip.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Playhead
              Positioned(
                left: _secondsToPosition(widget.playheadPosition),
                top: 0,
                bottom: 0,
                child: AnimatedPlayhead(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Playhead: vertical line with a dot and pulsing animation.
class AnimatedPlayhead extends StatefulWidget {
  const AnimatedPlayhead({super.key});

  @override
  State<AnimatedPlayhead> createState() => _AnimatedPlayheadState();
}

class _AnimatedPlayheadState extends State<AnimatedPlayhead>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final pulse = 0.7 + 0.3 * _ctrl.value;
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFEC4899),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.5),
                blurRadius: 6 * pulse,
                spreadRadius: 1 * pulse,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: 2,
            color: const Color(0xFFEC4899),
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
        ),
      ],
    );
  }
}

/// Ruler with time markers.
class _TimelineRulerPainter extends CustomPainter {
  _TimelineRulerPainter(this.durationSeconds, this.width);
  final double durationSeconds;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final step = durationSeconds / 5;
    for (int i = 0; i <= 5; i++) {
      final x = (i / 5) * width;
      canvas.drawLine(Offset(x, 20), Offset(x, 24), paint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i.toInt()}s',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineRulerPainter old) =>
      old.durationSeconds != durationSeconds || old.width != width;
}

/// Interactive slider with glow (for volume, speed, opacity).
class NeonSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String label;
  const NeonSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    required this.onChanged,
    required this.label,
  });

  @override
  State<NeonSlider> createState() => _NeonSliderState();
}

class _NeonSliderState extends State<NeonSlider> {
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            Text(
              '${(widget.value * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragValue += details.delta.dx / 200;
              _dragValue = _dragValue.clamp(0, 1);
              widget.onChanged(_dragValue);
            });
          },
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 6,
                width: widget.value.clamp(0, 1) * double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8855FF), Color(0xFF00D5FF)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Positioned(
                left: widget.value.clamp(0, 1) - 0.05,
                top: -6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8855FF),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF8855FF),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Transition preview chip.
class TransitionPreview extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const TransitionPreview({
    super.key,
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF8855FF).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: selected
                ? const Color(0xFF8855FF)
                : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? const Color(0xFF8855FF) : const Color(0xFF94A3B8), size: 24),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: selected ? const Color(0xFF8855FF) : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

