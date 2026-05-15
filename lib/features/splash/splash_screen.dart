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
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController, curve: Curves.easeIn),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController, curve: Curves.easeIn),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _textController, curve: Curves.easeOut));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _taglineController, curve: Curves.easeIn),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _taglineController.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated logo ──────────────────────────────
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.teal.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/android/Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Animated app name ──────────────────────────
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) => FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: const Text(
                    'BudgetKo',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Animated tagline ───────────────────────────
            AnimatedBuilder(
              animation: _taglineController,
              builder: (context, child) => FadeTransition(
                opacity: _taglineOpacity,
                child: const Text(
                  'Manage your money',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // ── Loading indicator ──────────────────────────
            AnimatedBuilder(
              animation: _taglineController,
              builder: (context, child) => FadeTransition(
                opacity: _taglineOpacity,
                child: SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor:
                        AppColors.teal.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.teal),
                    minHeight: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
