import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/transactions/transactions_screen.dart';
import '../features/transactions/quick_add_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/recurring/recurring_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/wallets/wallets_screen.dart';
import '../features/settings/settings_screen.dart';
import '../core/theme/app_theme.dart';

// ── Global drawer key ──────────────────────────────────────────────────────────

final _drawerKey = GlobalKey<ScaffoldState>();

void openDrawer() {
  _drawerKey.currentState?.openDrawer();
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (c, s) => const SplashScreen(),
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
            path: '/goals',
            builder: (c, s) => const GoalsScreen()),
        GoRoute(
            path: '/alerts',
            builder: (c, s) => const AlertsScreen()),
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

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final showQuickAdd =
        location != '/goals' &&
        location != '/recurring' &&
        location != '/wallets' &&
        location != '/settings';

    return Scaffold(
      key: _drawerKey,
      backgroundColor: AppColors.bg,
      drawer: _AppDrawer(),
      body: child,
      floatingActionButton: showQuickAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/quick-add'),
              backgroundColor: AppColors.teal,
              elevation: 0,
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: const Text(
                'Quick Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: showQuickAdd
          ? FloatingActionButtonLocation.centerFloat
          : null,
    );
  }
}

// ── Side drawer ────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/android/Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BudgetKo',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Manage your money',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Nav items ────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    path: '/',
                    currentPath: location,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'Transactions',
                    path: '/transactions',
                    currentPath: location,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/transactions');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    label: 'Wallets',
                    path: '/wallets',
                    currentPath: location,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/wallets');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.savings_outlined,
                    activeIcon: Icons.savings,
                    label: 'Savings Goals',
                    path: '/goals',
                    currentPath: location,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/goals');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications,
                    label: 'Spending Limits',
                    path: '/alerts',
                    currentPath: location,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/alerts');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.repeat_outlined,
                    activeIcon: Icons.repeat,
                    label: 'Recurring',
                    path: '/recurring',
                    currentPath: location,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/recurring');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: 'Reports',
                    path: '/reports',
                    currentPath: location,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/reports');
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                    path: '/settings',
                    currentPath: location,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'BudgetKo v2.0',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer item ────────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final String currentPath;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.onTap,
  });

  bool get isActive => currentPath == path;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.teal.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.teal.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? AppColors.teal
                  : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppColors.teal
                    : AppColors.textPrimary,
                fontWeight: isActive
                    ? FontWeight.w600
                    : FontWeight.w400,
                fontSize: 15,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
