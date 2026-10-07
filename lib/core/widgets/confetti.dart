import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One confetti particle.
class _Particle {
  late final double x = _rnd.nextDouble() * size.width;
  late final double y = -20 - _rnd.nextDouble() * size.height * 0.5;
  late final double w = 5 + _rnd.nextDouble() * 7;
  late final double h = w * (0.5 + _rnd.nextDouble());
  late final double vx = (_rnd.nextDouble() - 0.5) * 2.4;
  late final double vy = 2.2 + _rnd.nextDouble() * 3.4;
  late final double spin = (_rnd.nextDouble() - 0.5) * 0.28;
  late final double spinSpeed = (_rnd.nextDouble() - 0.5) * 0.22;
  late final double drift = 0.4 + _rnd.nextDouble() * 1.2;
  late final double wobble = _rnd.nextDouble() * math.pi * 2;
  late final Color color = _palette[_rnd.nextInt(_palette.length)];
  double angle = 0;

  final math.Random _rnd = math.Random();
  late final Size size;

  static const _palette = <Color>[
    AppColors.teal,
    AppColors.income,
    AppColors.expense,
    AppColors.warning,
    Color(0xFFA78BFA),
    Color(0xFFEC4899),
    Color(0xFF38BDF8),
  ];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final t = progress * 900 + p.y;
      final y = t % (size.height + 60) - 20;
      final x = p.x + math.sin((progress * p.drift) + p.wobble) * 26;
      final opacity = y > size.height * 0.72
          ? (1 - (y - size.height * 0.72) / (size.height * 0.28)).clamp(0.0, 1.0)
          : 1.0;
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.w,
            height: p.h,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

/// Full screen confetti burst. Call [ConfettiOverlay.show] to fire it.
class ConfettiOverlay {
  const ConfettiOverlay._();

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiController(onDone: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _ConfettiController extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiController({required this.onDone});

  @override
  State<_ConfettiController> createState() => _ConfettiControllerState();
}

class _ConfettiControllerState extends State<_ConfettiController>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Fade the whole burst out over the last third.
          final fade = _controller.value < 0.66
              ? 1.0
              : (1 - (_controller.value - 0.66) / 0.34).clamp(0.0, 1.0);
          if (fade <= 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onDone();
            });
          }
          return Opacity(
            opacity: fade,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(
                List.generate(90, (i) {
                  final p = _Particle()..size = MediaQuery.sizeOf(context);
                  // Advance each particle so they are already falling
                  // on the first frame instead of dropping in.
                  p.angle = _controller.value * 8 + i;
                  return p;
                }),
                _controller.value,
              ),
            ),
          );
        },
      ),
    );
  }
}
