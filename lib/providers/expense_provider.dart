import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../services/hive_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final HiveService _hive;
  final AnalyticsService _analytics = AnalyticsService();

  List<Expense> _expenses = [];
  String? _categoryFilter;
  bool _isLoading = false;

  ExpenseProvider(this._hive) {
    _load();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get categoryFilter => _categoryFilter;

  List<Expense> get filteredExpenses {
    if (_categoryFilter == null) return _expenses;
    return _expenses.where((e) => e.category == _categoryFilter).toList();
  }

  double get monthlyTotal => _analytics.getMonthlyTotal(_expenses);
  Map<String, double> get categoryBreakdown =>
      _analytics.getCategoryBreakdown(_expenses);
  String? get topCategory => _analytics.getTopCategory(_expenses);
  List<Map<String, dynamic>> get weeklySummary =>
      _analytics.getWeeklySummary(_expenses);
  String? get overspendingCategory =>
      _analytics.getOverspendingCategory(_expenses);
  List<Map<String, dynamic>> get habits => _analytics.getHabits(_expenses);

  // ── Actions ───────────────────────────────────────────────────────────────
  void _load() {
    _expenses = _hive.getAllExpenses();
    notifyListeners();
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required DateTime date,
    String? note,
    Budget? budget,
  }) async {
    _isLoading = true;
    notifyListeners();

    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
    await _hive.addExpense(expense);
    _load();
    _isLoading = false;

    // Budget alert check
    if (budget != null) {
      final newTotal = _analytics.getMonthlyTotal(_expenses);
      final dailyTotal = _analytics.getDailyTotal(_expenses);

      // Daily limit check
      if (budget.dailyLimit > 0 && dailyTotal > budget.dailyLimit) {
        await NotificationService.showBudgetAlert(
          title: 'Daily Limit Exceeded! ⚠️',
          body: "You've spent Rs. ${dailyTotal.toStringAsFixed(0)} today, "
              "exceeding your Rs. ${budget.dailyLimit.toStringAsFixed(0)} daily limit.",
        );
      }

      // Monthly limit check
      if (budget.monthlyLimit > 0) {
        if (newTotal > budget.monthlyLimit) {
          await NotificationService.showBudgetAlert(
            title: 'Monthly Budget Exceeded! 🚨',
            body: "You've spent Rs. ${newTotal.toStringAsFixed(0)} – "
                "over your Rs. ${budget.monthlyLimit.toStringAsFixed(0)} limit.",
          );
        } else if (newTotal > budget.monthlyLimit * 0.8) {
          await NotificationService.showBudgetAlert(
            title: 'Monthly Budget Warning ⚠️',
            body: '80% of your monthly budget used. '
                'Only Rs. ${(budget.monthlyLimit - newTotal).toStringAsFixed(0)} left.',
          );
        }
      }
    }
    notifyListeners();
  }

  Future<void> triggerWeeklySummary() async {
    final summary = _analytics.getWeeklySummary(_expenses);
    final total = summary.fold(0.0, (sum, item) => sum + (item['total'] as double));
    await NotificationService.showWeeklySummary(
      body: 'You spent Rs. ${total.toStringAsFixed(0)} this week. '
          'Check the Insights tab for a full breakdown!',
    );
  }

  Future<void> deleteExpense(String id) async {
    await _hive.deleteExpense(id);
    _load();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _hive.clearAll();
    _load();
  }
}
