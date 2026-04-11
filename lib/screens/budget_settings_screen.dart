import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final _monthlyController = TextEditingController();
  final _dailyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budget = context.read<BudgetProvider>().budget;
      if (budget != null) {
        _monthlyController.text = budget.monthlyLimit.toStringAsFixed(0);
        _dailyController.text = budget.dailyLimit.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _monthlyController.dispose();
    _dailyController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final monthly = double.tryParse(_monthlyController.text) ?? 0;
    final daily = double.tryParse(_dailyController.text) ?? 0;
    await context
        .read<BudgetProvider>()
        .saveBudget(monthlyLimit: monthly, dailyLimit: daily);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Budget saved successfully!'),
          ]),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsCard(
            icon: Icons.calendar_month_rounded,
            iconColor: AppTheme.primary,
            title: 'Monthly Limit',
            child: TextField(
              controller: _monthlyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 25000',
                prefixText: 'Rs. ',
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 16),

          _SettingsCard(
            icon: Icons.today_rounded,
            iconColor: AppTheme.warning,
            title: 'Daily Limit',
            child: TextField(
              controller: _dailyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 1000',
                prefixText: 'Rs. ',
              ),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saveBudget,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Budget'),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
