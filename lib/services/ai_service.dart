import '../models/expense.dart';
import 'analytics_service.dart';

class AiService {
  final AnalyticsService _analytics = AnalyticsService();

  List<String> getSuggestions(List<Expense> expenses) {
    final suggestions = <String>[];
    final total = _analytics.getMonthlyTotal(expenses);
    if (total == 0) {
      suggestions.add('Start tracking your expenses to receive AI tips! 🚀');
      return suggestions;
    }

    final breakdown = _analytics.getCategoryBreakdown(expenses);
    final top = _analytics.getTopCategory(expenses);

    // Tip 1 – Overspending category
    final overspending = _analytics.getOverspendingCategory(expenses);
    if (overspending != null) {
      final pct = ((breakdown[overspending]! / total) * 100).toStringAsFixed(0);
      suggestions.add(
          '🔴 You\'re spending $pct% of your budget on $overspending. '
          'Try to reduce it below 40%.');
    }

    // Tip 2 – High food spend
    if ((breakdown['food'] ?? 0) > total * 0.3) {
      final saving = (breakdown['food']! * 0.2).toStringAsFixed(0);
      suggestions.add(
          '🍔 Cooking at home just twice a week could save you Rs. $saving this month.');
    }

    // Tip 3 – Transport
    if ((breakdown['transport'] ?? 0) > total * 0.2) {
      suggestions.add(
          '🚌 Consider carpooling or public transit to cut transport costs.');
    }

    // Tip 4 – Shopping
    if ((breakdown['shopping'] ?? 0) > total * 0.25) {
      suggestions.add(
          '🛒 Unsubscribe from shopping apps for 2 weeks – it breaks impulse-buy habits.');
    }

    // Tip 5 – Habits
    final habits = _analytics.getHabits(expenses);
    for (final habit in habits.take(2)) {
      final cat = habit['category'];
      final monthlyTotal = (habit['total'] as double).toStringAsFixed(0);
      suggestions.add(
          '📅 Your daily $cat habit costs Rs. $monthlyTotal/month. '
          'Cutting it by 30% saves Rs. ${(habit['total'] * 0.3).toStringAsFixed(0)}.');
    }

    // Tip 6 – General savings (always shown if list is short)
    if (suggestions.length < 2) {
      final save = (total * 0.1).toStringAsFixed(0);
      suggestions.add(
          '💡 Setting aside 10% of your income (Rs. $save) each month builds an emergency fund in 6 months.');
    }

    return suggestions;
  }

  Map<String, String> getAnalysis(List<Expense> expenses) {
    final total = _analytics.getMonthlyTotal(expenses);
    final top = _analytics.getTopCategory(expenses) ?? 'None';
    final overspending = _analytics.getOverspendingCategory(expenses);
    final suggestions = getSuggestions(expenses);

    return {
      'topCategory': top,
      'warning': overspending != null 
          ? '⚠️ Overspending detected in $overspending (>40%)!' 
          : '✅ No major overspending detected.',
      'advice': suggestions.isNotEmpty ? suggestions.first : 'Keep up the good work!',
    };
  }

  String getMotivationalMessage(double spent, double limit) {
    if (limit == 0) return 'Set a budget to track your progress! 🎯';
    final pct = (spent / limit) * 100;
    if (pct < 50) return 'Great job! You\'re well within budget 🌟';
    if (pct < 80) return 'Spend wisely – you\'re at ${pct.toStringAsFixed(0)}% of your limit ⚡';
    if (pct < 100) return 'Warning! Only ${(limit - spent).toStringAsFixed(0)} left in budget ⚠️';
    return 'Budget exceeded! Time to cut back 🚨';
  }
}
