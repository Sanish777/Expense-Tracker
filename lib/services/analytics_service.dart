import '../models/expense.dart';
import '../models/app_category.dart';

class AnalyticsService {
  // ── Monthly Total ─────────────────────────────────────────────────────────
  double getMonthlyTotal(List<Expense> expenses) {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // ── Daily Total ──────────────────────────────────────────────────────────
  double getDailyTotal(List<Expense> expenses) {
    final now = DateTime.now();
    return expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // ── Category Breakdown ────────────────────────────────────────────────────
  Map<String, double> getCategoryBreakdown(List<Expense> expenses) {
    final now = DateTime.now();
    final monthly = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month);
    final Map<String, double> breakdown = {};
    for (final expense in monthly) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }
    return breakdown;
  }

  // ── Top Category ─────────────────────────────────────────────────────────
  String? getTopCategory(List<Expense> expenses) {
    final breakdown = getCategoryBreakdown(expenses);
    if (breakdown.isEmpty) return null;
    return breakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // ── Weekly Summary (last 7 days, day-by-day) ──────────────────────────────
  List<Map<String, dynamic>> getWeeklySummary(List<Expense> expenses) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final total = expenses
          .where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold(0.0, (sum, e) => sum + e.amount);
      return {'day': day, 'total': total};
    });
  }

  // ── Overspending Check ────────────────────────────────────────────────────
  /// Returns category name if it exceeds 40 % of total, else null.
  String? getOverspendingCategory(List<Expense> expenses) {
    final total = getMonthlyTotal(expenses);
    if (total == 0) return null;
    final breakdown = getCategoryBreakdown(expenses);
    for (final entry in breakdown.entries) {
      if (entry.value / total > 0.4) return entry.key;
    }
    return null;
  }

  // ── Habit Detection ───────────────────────────────────────────────────────
  /// Returns categories that appear on 5+ distinct days in the current month.
  List<Map<String, dynamic>> getHabits(List<Expense> expenses) {
    final now = DateTime.now();
    final monthly = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();

    final Map<String, Set<int>> daysByCategory = {};
    final Map<String, double> totalByCategory = {};
    for (final e in monthly) {
      daysByCategory.putIfAbsent(e.category, () => {}).add(e.date.day);
      totalByCategory[e.category] =
          (totalByCategory[e.category] ?? 0) + e.amount;
    }

    return daysByCategory.entries
        .where((entry) => entry.value.length >= 5)
        .map((entry) => {
              'category': entry.key,
              'days': entry.value.length,
              'total': totalByCategory[entry.key] ?? 0.0,
            })
        .toList();
  }
}
