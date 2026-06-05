import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processDueRecurring();
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
    }
  }

  Future<void> _processDueRecurring() async {
    if (_processingRecurring) return;
    _processingRecurring = true;
    try {
      final createdCount =
          await ref.read(databaseProvider).processDueRecurring();
      if (!mounted || createdCount == 0) return;

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
