import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _drift;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _ruleScale;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.32, 0.68, curve: Curves.easeOut),
      ),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero)
            .animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.32, 0.75, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.52, 0.85, curve: Curves.easeOut),
      ),
    );
    _ruleScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.6, 0.95, curve: Curves.easeOut),
      ),
    );

    _entrance.forward().whenComplete(_goHome);
  }

  void _goHome() {
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: _BackdropWash()),
          const Positioned.fill(child: _ChartMotif()),
          Positioned.fill(child: _DriftingOrbs(animation: _drift)),
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _entrance,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius:
                                    BorderRadius.circular(28),
                                border: Border.all(
                                  color: AppColors.teal
                                      .withValues(alpha: 0.35),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal
                                        .withValues(alpha: 0.35),
                                    blurRadius: 36,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/android/Logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Opacity(
                          opacity: _textOpacity.value,
                          child: SlideTransition(
                            position: _textSlide,
                            child: const Text(
                              'BudgetKo',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: _taglineOpacity.value,
                          child: const Text(
                            'Manage your money',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Opacity(
                          opacity: _ruleScale.value,
                          child: Transform.scale(
                            scaleX: _ruleScale.value,
                            alignment: Alignment.center,
                            child: Container(
                              width: 96,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.teal
                                        .withValues(alpha: 0),
                                    AppColors.teal,
                                    AppColors.teal
                                        .withValues(alpha: 0),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropWash extends StatelessWidget {
  const _BackdropWash();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.75),
          radius: 1.1,
          colors: [Color(0xFF12241F), AppColors.bg],
        ),
      ),
    );
  }
}

class _DriftingOrbs extends StatelessWidget {
  final Animation<double> animation;
  const _DriftingOrbs({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final a = t * 2 * math.pi;
        return Stack(
          children: [
            Align(
              alignment: const Alignment(-0.75, -0.55),
              child: Transform.translate(
                offset: Offset(
                  math.sin(a) * 26,
                  math.cos(a * 0.8) * 34,
                ),
                child: const _GlowOrb(
                  size: 300,
                  color: AppColors.teal,
                  opacity: 0.20,
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.85, -0.1),
              child: Transform.translate(
                offset: Offset(
                  math.cos(a * 0.7) * 30,
                  math.sin(a * 1.1) * 26,
                ),
                child: const _GlowOrb(
                  size: 220,
                  color: AppColors.tealLight,
                  opacity: 0.12,
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.2, 0.85),
              child: Transform.translate(
                offset: Offset(
                  math.sin(a * 1.3) * 38,
                  math.cos(a * 0.6) * 22,
                ),
                child: const _GlowOrb(
                  size: 260,
                  color: AppColors.savings,
                  opacity: 0.10,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartMotif extends StatelessWidget {
  const _ChartMotif();

  static const List<double> _heights = [
    38,
    62,
    46,
    88,
    58,
    104,
    74,
    126,
    92,
    68,
    112,
    54,
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Opacity(
          opacity: 0.07,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in _heights)
                  Container(
                    width: 16,
                    height: h,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(4),
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
