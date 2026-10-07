import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One confetti particle. Generated once per burst and mutated per frame
/// by the painter, never rebuilt.
class _Particle {
  _Particle(this._rnd, this.size) {
    x = _rnd.nextDouble() * size.width;
    y = -20 - _rnd.nextDouble() * size.height * 0.5;
    w = 6 + _rnd.nextDouble() * 7;
    h = w * (0.5 + _rnd.nextDouble());
    vx = (_rnd.nextDouble() - 0.5) * 2.4;
    vy = 2.2 + _rnd.nextDouble() * 3.4;
    spinSpeed = (_rnd.nextDouble() - 0.5) * 0.22;
    drift = 0.4 + _rnd.nextDouble() * 1.2;
    wobble = _rnd.nextDouble() * math.pi * 2;
    color = _palette[_rnd.nextInt(_palette.length)];
    rotation = _rnd.nextDouble() * math.pi * 2;
  }

  final math.Random _rnd;

  static const _palette = <Color>[
    AppColors.teal,
    AppColors.income,
    AppColors.expense,
    AppColors.warning,
    Color(0xFFA78BFA),
    Color(0xFFEC4899),
    Color(0xFF38BDF8),
  ];

  final Size size;

  late final double x;
  late final double y;
  late final double w;
  late final double h;
  late final double vx;
  late final double vy;
  late final double spinSpeed;
  late final double drift;
  late final double wobble;
  late final Color color;
  late double rotation;

  double angle = 0;

  void advance(double frames) {
    angle += spinSpeed;
    // The particle walks down and wraps, so the burst keeps going for the
    // whole animation instead of emptying out.
    y += vy;
    if (y > size.height + 30) {
      y = -20 - _rnd.nextDouble() * 60;
      x = _rnd.nextDouble() * size.width;
    }
  }

  double get drawX => x + math.sin((y / 90) * drift + wobble) * 24;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.opacity);

  final List<_Particle> particles;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      // Fade individual pieces out over the last third of the fall.
      final fade = p.y > size.height * 0.7
          ? (1 - (p.y - size.height * 0.7) / (size.height * 0.3))
                  .clamp(0.0, 1.0)
          : 1.0;
      final alpha = (fade * opacity).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      paint.color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(p.drawX, p.y);
      canvas.rotate(p.rotation + p.angle);
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

/// Fires a full screen confetti burst. Safe to call from a button press.
class ConfettiOverlay {
  const ConfettiOverlay._();

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiBurst(onDone: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _ConfettiBurst extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiBurst({required this.onDone});

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _count = 90;

  late final AnimationController _controller;

  /// Built once on first layout, when the screen size is known.
  List<_Particle>? _particles;

  var _removing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )
      // Removal is driven by the animation status, never from build, so
      // the entry is never unmounted while it is still building.
      ..addStatusListener(_onStatus)
      ..forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_removing || !mounted) return;
    _removing = true;
    // Let this frame finish before the entry is torn down.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _particles ??= List.generate(
      _count,
      (i) => _Particle(math.Random(i * 7919 + 13), size),
    );

    // Fade the burst out over the last third.
    final opacity = (_controller.value < 0.66
            ? 1.0
            : (1 - (_controller.value - 0.66) / 0.34))
        .clamp(0.0, 1.0);

    if (opacity <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox.expand(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final particles = _particles!;
              // Rotation is derived from the animation clock, so the
              // painter only draws and never allocates.
              final frames =
                  (_controller.lastElapsedDuration?.inMicroseconds ?? 0) ~/
                      16667;
              for (final p in particles) {
                p.angle = frames * p.spinSpeed;
              }
              return CustomPaint(
                painter: _ConfettiPainter(particles, opacity),
              );
            },
          ),
        ),
      ),
    );
  }
}
