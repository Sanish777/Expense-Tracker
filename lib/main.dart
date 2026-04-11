import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'providers/expense_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart'; // Still keep Hive for Theme for now to avoid migration overhead
import 'theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  final hiveService = HiveService();
  await hiveService.init();
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: dbService),
        Provider<AuthService>(create: (ctx) => AuthService(ctx.read<DatabaseService>())),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(DatabaseService()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ExpenseProvider(ctx.read<DatabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => BudgetProvider(ctx.read<DatabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ThemeProvider(hiveService),
        ),
      ],
      child: const SpendWiseApp(),
    ),
  );
}

// SpendWiseApp is now imported from app.dart
