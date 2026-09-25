import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgetko/features/categories/categories_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/transactions/transactions_screen.dart';
import '../features/transactions/quick_add_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/recurring/recurring_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/wallets/wallets_screen.dart';
import '../features/settings/settings_screen.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/providers.dart';

// ── Navigation destinations ────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: onboardingComplete,
  redirect: (context, state) {
    final location = state.matchedLocation;
    if (onboardingComplete.value) {
      return location == '/onboarding' ? '/' : null;
    }
    const allowed = {'/splash', '/onboarding'};
    return allowed.contains(location) ? null : '/onboarding';
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (c, s) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (c, s) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/quick-add',
      builder: (c, s) => const QuickAddScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
            path: '/',
            builder: (c, s) => const DashboardScreen()),
        GoRoute(
            path: '/transactions',
            builder: (c, s) => const TransactionsScreen()),
        GoRoute(
            path: '/notifications',
            builder: (c, s) => const NotificationsScreen()),
        GoRoute(
            path: '/goals',
            builder: (c, s) => const GoalsScreen()),
        GoRoute(
            path: '/alerts',
            builder: (c, s) => const AlertsScreen()),
        GoRoute(
            path: '/categories',
            builder: (c, s) => const CategoriesScreen()),
        GoRoute(
            path: '/recurring',
            builder: (c, s) => const RecurringScreen()),
        GoRoute(
            path: '/reports',
            builder: (c, s) => const ReportsScreen()),
        GoRoute(
            path: '/wallets',
            builder: (c, s) => const WalletsScreen()),
        GoRoute(
            path: '/settings',
            builder: (c, s) => const SettingsScreen()),
      ],
    ),
  ],
);

// ── App shell with side drawer ─────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _maxHistory = 30;
  final List<String> _history = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    if (_history.isEmpty || _history.last != location) {
      setState(() {
        _history.add(location);
        if (_history.length > _maxHistory) {
          _history.removeAt(0);
        }
      });
    }
  }

  void _goBack() {
    if (_history.length <= 1) return;
    setState(() => _history.removeLast());
    context.go(_history.last);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;

    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        // Lets each screen's content scroll underneath the floating bar
        // instead of stopping at a hard edge above it.
        extendBody: true,
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey(location),
                child: widget.child,
              ),
            ),
            if (isCurrent)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _FloatingNavBar(location: location),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Curved bottom navigation ───────────────────────────────────────────────────

class _NavTabSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavTabSpec(
      this.icon, this.activeIcon, this.label, this.path);
}

const List<_NavTabSpec> _kNavTabs = [
  _NavTabSpec(Icons.home_outlined, Icons.home, 'Home', '/'),
  _NavTabSpec(Icons.receipt_long_outlined, Icons.receipt_long,
      'Transactions', '/transactions'),
  _NavTabSpec(Icons.speed_outlined, Icons.speed, 'Budgets', '/alerts'),
];

class _MoreDest {
  final IconData icon;
  final String label;
  final String path;
  const _MoreDest(this.icon, this.label, this.path);
}

const List<String> _kMorePaths = [
  '/reports',
  '/wallets',
  '/goals',
  '/categories',
  '/recurring',
  '/notifications',
  '/settings',
];

const List<_MoreDest> _kMoreDests = [
  _MoreDest(Icons.bar_chart_outlined, 'Reports', '/reports'),
  _MoreDest(
      Icons.account_balance_wallet_outlined, 'Wallets', '/wallets'),
  _MoreDest(Icons.savings_outlined, 'Savings Goals', '/goals'),
  _MoreDest(Icons.category_outlined, 'Categories', '/categories'),
  _MoreDest(Icons.repeat_outlined, 'Recurring', '/recurring'),
  _MoreDest(
      Icons.notifications_outlined, 'Notifications', '/notifications'),
  _MoreDest(Icons.settings_outlined, 'Settings', '/settings'),
];

class _FloatingNavBar extends StatelessWidget {
  final String location;
  const _FloatingNavBar({required this.location});

  bool get _moreActive => _kMorePaths.contains(location);

  Future<void> _openMore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final router = GoRouter.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              for (final dest in _kMoreDests)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.teal
                          .withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(dest.icon,
                        color: AppColors.teal, size: 20),
                  ),
                  title: Text(
                    dest.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: location == dest.path
                      ? const Icon(Icons.check,
                          color: AppColors.teal, size: 18)
                      : const Icon(Icons.chevron_right,
                          color: AppColors.textHint, size: 18),
                  onTap: () {
                    nav.pop();
                    router.go(dest.path);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (messenger.mounted) {
      messenger.hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inset from every edge so the pill reads as a detached object
    // rather than a bar bolted to the bottom of the screen.
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: SizedBox(
        height: 62,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(31),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(31),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 20,
                      sigmaY: 20,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard
                            .withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(31),
                        border: Border.all(
                          color:
                              Colors.white.withValues(alpha: 0.07),
                          width: 1,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
              Positioned.fill(
                child: Row(
                  children: [
                    _NavTab(
                      spec: _kNavTabs[0],
                      selected: location == _kNavTabs[0].path,
                      onTap: () =>
                          context.go(_kNavTabs[0].path),
                    ),
                    _NavTab(
                      spec: _kNavTabs[1],
                      selected: location == _kNavTabs[1].path,
                      onTap: () =>
                          context.go(_kNavTabs[1].path),
                    ),
                    const SizedBox(width: 64),
                    _NavTab(
                      spec: _kNavTabs[2],
                      selected: location == _kNavTabs[2].path,
                      showBadge: true,
                      onTap: () =>
                          context.go(_kNavTabs[2].path),
                    ),
                    _NavTab(
                      spec: const _NavTabSpec(
                          Icons.more_horiz, Icons.more_horiz,
                          'More', ''),
                      selected: _moreActive,
                      onTap: () => _openMore(context),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: -23,
                child: Center(
                  child: _QuickAddDockButton(
                      origin: location),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _NavTab extends StatelessWidget {
  final _NavTabSpec spec;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;
  const _NavTab({
    required this.spec,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      selected ? spec.activeIcon : spec.icon,
                      key: ValueKey(selected),
                      color: selected
                          ? AppColors.teal
                          : AppColors.textSecondary,
                      size: 21,
                    ),
                  ),
                  if (showBadge) const _OverBudgetDot(),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: selected
                      ? AppColors.teal
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                child: Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverBudgetDot extends ConsumerWidget {
  const _OverBudgetDot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync =
        ref.watch(categoryBudgetStatusProvider);
    final count = statusesAsync.valueOrNull
            ?.where((s) => s.isOver)
            .length ??
        0;
    if (count == 0) return const SizedBox.shrink();
    return Positioned(
      right: -5,
      top: -3,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.expense,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuickAddDockButton extends StatelessWidget {
  final String origin;
  const _QuickAddDockButton({required this.origin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealLight, AppColors.tealDark],
        ),
        border: Border.all(color: AppColors.bg, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push(
              '/quick-add?from=${Uri.encodeComponent(origin)}'),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
