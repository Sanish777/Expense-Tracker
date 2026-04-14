import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _db;
  final AnalyticsService _analytics = AnalyticsService();

  List<Expense> _expenses = [];
  String? _categoryFilter;
  TimeRange _timeFilter = TimeRange.allTime;
  DateTimeRange? _customDateRange;
  bool _isLoading = false;

  ExpenseProvider(this._db) {
    _load();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get categoryFilter => _categoryFilter;
  TimeRange get timeFilter => _timeFilter;
  DateTimeRange? get customDateRange => _customDateRange;

  List<Expense> get filteredExpenses {
    var list = _expenses;
    
    // Time filtering
    if (_timeFilter == TimeRange.thisMonth) {
      final now = DateTime.now();
      list = list.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else if (_timeFilter == TimeRange.thisWeek) {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      list = list.where((e) => e.date.isAfter(lastWeek)).toList();
    } else if (_timeFilter == TimeRange.custom && _customDateRange != null) {
      list = list.where((e) => 
        e.date.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1))) && 
        e.date.isBefore(_customDateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    // Category filtering
    if (_categoryFilter != null) {
      list = list.where((e) => e.category == _categoryFilter).toList();
    }
    
    return list;
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
  Future<void> _load() async {
    _expenses = await _db.getExpenses();
    notifyListeners();
  }

  Future<void> reloadData() async {
    await _load();
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
    await _db.insertExpense(expense);
    await _load();
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

  Future<void> addExpenses({
    required List<Expense> expenses,
    Budget? budget,
  }) async {
    if (expenses.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    await _db.insertExpenses(expenses);
    await _load();
    _isLoading = false;

    if (budget != null) {
      final newTotal = _analytics.getMonthlyTotal(_expenses);
      final dailyTotal = _analytics.getDailyTotal(_expenses);

      if (budget.dailyLimit > 0 && dailyTotal > budget.dailyLimit) {
        await NotificationService.showBudgetAlert(
          title: 'Daily Limit Exceeded! ⚠️',
          body: "You've spent Rs. ${dailyTotal.toStringAsFixed(0)} today, "
              "exceeding your Rs. ${budget.dailyLimit.toStringAsFixed(0)} daily limit.",
        );
      }

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
    await _db.deleteExpense(id);
    await _load();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setTimeFilter(TimeRange range, {DateTimeRange? customRange}) {
    _timeFilter = range;
    if (range == TimeRange.custom && customRange != null) {
      _customDateRange = customRange;
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _db.clearAll();
    await _load();
  }
}

enum TimeRange { allTime, thisMonth, thisWeek, custom }
