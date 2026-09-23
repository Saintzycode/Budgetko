import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_triggers.dart';
import 'data/repositories/providers.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Local notifications
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  // Onboarding state must be known before the router builds
  await loadOnboardingState();

  runApp(
    const ProviderScope(
      child: BudgetKoApp(),
    ),
  );
}

class BudgetKoApp extends ConsumerStatefulWidget {
  const BudgetKoApp({super.key});

  @override
  ConsumerState<BudgetKoApp> createState() => _BudgetKoAppState();
}

class _BudgetKoAppState extends ConsumerState<BudgetKoApp>
    with WidgetsBindingObserver {
  Timer? _recurringTimer;
  bool _processingRecurring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.onTap =
        (payload) => _handleNotificationTap(payload);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _processDueRecurring();
      await _runNotificationChecks();
    });
    _recurringTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _processDueRecurring(),
    );
  }

  @override
  void dispose() {
    _recurringTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processDueRecurring();
      _runNotificationChecks();
    }
  }

  Future<void> _processDueRecurring() async {
    if (_processingRecurring) return;
    _processingRecurring = true;
    try {
      final createdCount =
          await ref.read(databaseProvider).processDueRecurring();
      if (!mounted || createdCount == 0) return;

      await notifyRecurring(
          ref.read(databaseProvider), createdCount);

      ref
        ..invalidate(allTransactionsProvider)
        ..invalidate(transactionsForMonthProvider)
        ..invalidate(monthlyTotalsProvider)
        ..invalidate(spendingByCategoryProvider)
        ..invalidate(last6MonthsProvider)
        ..invalidate(allRecurringProvider)
        ..invalidate(allWalletsProvider);

      _showRecurringNotification(createdCount);
    } catch (error, stackTrace) {
      debugPrint('Recurring processing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _processingRecurring = false;
    }
  }

  Future<void> _runNotificationChecks() async {
    try {
      final db = ref.read(databaseProvider);
      await checkBudgetAlerts(db);
      await checkGoalDeadlines(db);
      await refreshDailyReminder();
    } catch (error) {
      debugPrint('Notification checks failed: $error');
    }
  }

  Future<void> _handleNotificationTap(
      String? payload) async {
    try {
      if (payload == 'daily') {
        await logInbox(
          ref.read(databaseProvider),
          title: "Log today's spending",
          body:
              'A quick review keeps your budget on track.',
          type: 'daily',
          payload: 'daily',
        );
      }
      final route = notificationRouteFor(payload);
      if (route != null) appRouter.go(route);
    } catch (error) {
      debugPrint('Notification tap failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BudgetKo',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }

  void _showRecurringNotification(int createdCount) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          content: Text(
            createdCount == 1
                ? 'Recurring transaction added'
                : '$createdCount recurring transactions added',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }
}
