import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_service.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/history_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      ],
      child: const SpendWiseApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const MainShell(),
    );
  }
}

// ── Bottom-nav shell ──────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    HistoryScreen(),
    AddExpenseScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      // ── Centre FAB ──────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _currentIndex = 2),
        elevation: 6,
        child: AnimatedRotation(
          turns: _currentIndex == 2 ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ).animate(target: _currentIndex == 2 ? 1.0 : 0.0)
          .scaleXY(begin: 1.0, end: 0.92, duration: 150.ms),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom nav ──────────────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          // Tapping center slot goes to Add screen
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 16,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.cardDark
          : Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            _Item(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
                label: 'Home', index: 0, current: currentIndex, onTap: onTap),
            _Item(icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'History', index: 1, current: currentIndex, onTap: onTap),
            const Expanded(child: SizedBox()), // notch gap
            _Item(icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Insights', index: 3, current: currentIndex, onTap: onTap),
            _Item(icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings', index: 4, current: currentIndex, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;

  const _Item({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey(selected),
                color: selected ? AppTheme.primary : AppTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
