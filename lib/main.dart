import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_service.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive local storage
  final hiveService = HiveService();
  await hiveService.init();

  // Init notifications (no-op on web)
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<HiveService>.value(value: hiveService),
        ChangeNotifierProxyProvider<HiveService, ExpenseProvider>(
          create: (ctx) => ExpenseProvider(ctx.read<HiveService>()),
          update: (_, hive, prev) => prev ?? ExpenseProvider(hive),
        ),
        ChangeNotifierProxyProvider<HiveService, BudgetProvider>(
          create: (ctx) => BudgetProvider(ctx.read<HiveService>()),
          update: (_, hive, prev) => prev ?? BudgetProvider(hive),
        ),
      ],
      child: const _AppRoot(),
    ),
  );
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise AI',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      home: const _MainWrapper(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    // Import handled via app_theme directly in shell
    return brightness == Brightness.light
        ? _lightTheme()
        : _darkTheme();
  }

  ThemeData _lightTheme() => ThemeData.light(useMaterial3: true);
  ThemeData _darkTheme() => ThemeData.dark(useMaterial3: true);
}

// Lightweight wrapper that applies AppTheme properly
class _MainWrapper extends StatelessWidget {
  const _MainWrapper();

  @override
  Widget build(BuildContext context) {
    // Delegate fully to SpendWiseApp shell which has correct theming
    return const SpendWiseApp();
  }
}
