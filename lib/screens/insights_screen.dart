import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/spending_chart.dart';
import '../widgets/insight_card.dart';
import '../theme/app_theme.dart';
import '../models/app_category.dart';
import '../services/ai_service.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final suggestions = AiService().getSuggestions(expProv.expenses);
    final habits = expProv.habits;
    final weekly = expProv.weeklySummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // ── Spending Breakdown ─────────────────────────────────────────
          _SectionHeader(title: 'Spending Breakdown'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SpendingChart(breakdown: expProv.categoryBreakdown),
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // ── Weekly Trend ───────────────────────────────────────────────
          _SectionHeader(title: 'Weekly Trend'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: weekly.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final total = item['total'] as double;
                  final day = item['day'] as DateTime;
                  final weekMax = weekly.fold<double>(
                      0.0, (m, e) => (e['total'] as double) > m ? e['total'] as double : m);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          child: Text(
                            _dayLabel(day.weekday),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: weekMax > 0 ? total / weekMax : 0,
                              minHeight: 10,
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 60,
                          child: Text(
                            total > 0
                                ? 'Rs. ${total.toStringAsFixed(0)}'
                                : '',
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(
                      delay: Duration(milliseconds: 60 * i),
                      duration: 300.ms);
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── AI Suggestions ─────────────────────────────────────────────
          _SectionHeader(title: 'AI Suggestions 🤖'),
          ...suggestions.asMap().entries.map(
                (e) => InsightCard(tip: e.value, index: e.key)
                    .animate()
                    .fadeIn(
                        delay: Duration(milliseconds: 80 * e.key),
                        duration: 350.ms)
                    .slideX(begin: 0.05),
              ),

          // ── Habit Detection ─────────────────────────────────────────────
          if (habits.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: 'Detected Habits 📅'),
            ...habits.map((h) {
              final catProv = context.watch<CategoryProvider>();
              final catId = h['category'];
              final cat = catProv.findById(catId);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.warning.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Text(cat?.emoji ?? '📦',
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat?.title ?? 'Unknown',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text(
                            '${h['days']} days this month · Rs. ${(h['total'] as double).toStringAsFixed(0)} total',
                            style: TextStyle(
                                fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _dayLabel(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }
}
