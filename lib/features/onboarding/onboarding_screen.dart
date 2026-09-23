import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  final TextEditingController _incomeController =
      TextEditingController();
  final TextEditingController _budgetController =
      TextEditingController();
  int _page = 0;
  bool _saving = false;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    _incomeController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pageCount - 1;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_page == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final income = double.tryParse(
      _incomeController.text.replaceAll(',', '').trim(),
    );
    if (income != null && income > 0) {
      await ref
          .read(monthlyIncomeProvider.notifier)
          .setIncome(income);
    }
    final budget = double.tryParse(
      _budgetController.text.replaceAll(',', '').trim(),
    );
    if (budget != null && budget > 0) {
      await ref
          .read(monthlyBudgetProvider.notifier)
          .setBudget(budget);
    }
    await completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed:
                      _saving ? null : () => completeOnboarding(),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: _saving
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _WelcomePage(),
                  _AmountPage(
                    controller: _incomeController,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'What\'s your monthly income?',
                    subtitle:
                        'Used to show your savings rate. You can change this later.',
                    hint: 'e.g. 25000',
                  ),
                  _AmountPage(
                    controller: _budgetController,
                    icon: Icons.pie_chart_outline,
                    title: 'Set a monthly budget',
                    subtitle:
                        'A target for total monthly spending to keep you on track.',
                    hint: 'e.g. 15000',
                  ),
                  const _NotificationsPage(),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pageCount,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.teal
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _saving ? null : _back,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                AppColors.textSecondary,
                            side: const BorderSide(
                                color: AppColors.bgSurface,
                                width: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isLast
                                    ? 'Get started'
                                    : 'Next',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.4),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/android/Logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'BudgetKo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage your money',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 40),
          const _FeatureRow(
            icon: Icons.receipt_long_outlined,
            title: 'Track every transaction',
            subtitle: 'Log spending in seconds with Quick Add',
          ),
          const SizedBox(height: 20),
          const _FeatureRow(
            icon: Icons.pie_chart_outline,
            title: 'Stay on budget',
            subtitle: 'Per-category limits with 80% warnings',
          ),
          const SizedBox(height: 20),
          const _FeatureRow(
            icon: Icons.savings_outlined,
            title: 'Reach your goals',
            subtitle: 'Set savings targets and track progress',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.teal, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountPage extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;

  const _AmountPage({
    required this.controller,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.teal, size: 30),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              prefixText: '₱ ',
              prefixStyle: const TextStyle(
                color: AppColors.teal,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: AppColors.bgCard,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: AppColors.bgSurface, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.teal, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Optional — you can set this later in Settings',
            style:
                TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NotificationsPage extends ConsumerStatefulWidget {
  const _NotificationsPage();

  @override
  ConsumerState<_NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends ConsumerState<_NotificationsPage> {
  bool _granted = false;
  bool _requested = false;

  Future<void> _enable() async {
    setState(() => _requested = true);
    final granted = await NotificationService.instance
        .requestPermissions();
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _requested = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: AppColors.warning, size: 30),
          ),
          const SizedBox(height: 24),
          const Text(
            'Stay on top of your budget',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Get warned at 80% of a category limit, reminders to log spending, and alerts when you are close to a savings goal deadline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_granted || _requested) ? null : _enable,
              icon: _requested
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.teal,
                      ),
                    )
                  : Icon(
                      _granted
                          ? Icons.check_circle_outline
                          : Icons.notifications_outlined,
                      size: 18,
                      color: _granted
                          ? AppColors.income
                          : AppColors.teal,
                    ),
              label: Text(
                _granted
                    ? 'Notifications enabled'
                    : 'Enable notifications',
                style: TextStyle(
                  color: _granted
                      ? AppColors.income
                      : AppColors.teal,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: _granted
                      ? AppColors.income
                      : AppColors.teal,
                  width: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You can change this anytime in Settings',
            style:
                TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
