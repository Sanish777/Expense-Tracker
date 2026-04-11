import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_service.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.init();
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
        ChangeNotifierProvider(
          create: (ctx) => ThemeProvider(ctx.read<HiveService>()),
        ),
      ],
      child: const SpendWiseApp(),
    ),
  );
}

// SpendWiseApp is now imported from app.dart
