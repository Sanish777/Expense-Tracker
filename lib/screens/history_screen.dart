import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/app_category.dart';
import '../models/expense.dart';
import '../widgets/expense_card.dart';
import '../widgets/category_chip.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final catProv = context.watch<CategoryProvider>();
    final expenses = expProv.filteredExpenses;
    final selected = expProv.categoryFilter;

    // ── Group expenses by date ───────────────────────────────────────────
    final grouped = <DateTime, List<Expense>>{};
    for (var e in expenses) {
      final date = DateTime(e.date.year, e.date.month, e.date.day);
      grouped.putIfAbsent(date, () => []).add(e);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final flattenedItems = <dynamic>[];
    for (var date in sortedDates) {
      flattenedItems.add(date);
      flattenedItems.addAll(grouped[date]!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Time range filter row ───────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              children: [
                _TimeFilterChip(
                  label: 'All Time',
                  range: TimeRange.allTime,
                  selected: expProv.timeFilter == TimeRange.allTime,
                  onTap: () => expProv.setTimeFilter(TimeRange.allTime),
                ),
                _TimeFilterChip(
                  label: 'This Month',
                  range: TimeRange.thisMonth,
                  selected: expProv.timeFilter == TimeRange.thisMonth,
                  onTap: () => expProv.setTimeFilter(TimeRange.thisMonth),
                ),
                _TimeFilterChip(
                  label: 'Last 7 Days',
                  range: TimeRange.thisWeek,
                  selected: expProv.timeFilter == TimeRange.thisWeek,
                  onTap: () => expProv.setTimeFilter(TimeRange.thisWeek),
                ),
                _TimeFilterChip(
                  label: 'Custom Range',
                  range: TimeRange.custom,
                  selected: expProv.timeFilter == TimeRange.custom,
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: expProv.customDateRange,
                    );
                    if (range != null) {
                      expProv.setTimeFilter(TimeRange.custom, customRange: range);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Category filter row ─────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              children: [
                // "All Cat" chip
                GestureDetector(
                  onTap: () => expProv.setCategoryFilter(null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selected == null
                          ? AppTheme.primary.withOpacity(0.15)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected == null ? AppTheme.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '✨ All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected == null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected == null ? AppTheme.primary : null,
                        ),
                      ),
                    ),
                  ),
                ),
                ...catProv.categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: CategoryChip(
                        category: cat,
                        isSelected: selected == cat.id,
                        onTap: () => expProv.setCategoryFilter(
                            selected == cat.id ? null : cat.id),
                      ),
                    )),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── Expense list ────────────────────────────────────────────────
          Expanded(
            child: flattenedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64,
                            color: AppTheme.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('No expenses found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different filter',
                          style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: flattenedItems.length,
                    itemBuilder: (context, i) {
                      final item = flattenedItems[i];
                      
                      if (item is DateTime) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 20, 0, 12),
                          child: Text(
                            _formatDateHeader(item),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ).animate().fadeIn(delay: 50.ms);
                      }
                      
                      final expense = item as Expense;
                      return ExpenseCard(
                        expense: expense,
                        onDelete: () =>
                            expProv.deleteExpense(expense.id),
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: 20 * i),
                          duration: 300.ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'Today';
    if (itemDate == yesterday) return 'Yesterday';

    final day = date.day;
    String suffix = 'th';
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1: suffix = 'st'; break;
        case 2: suffix = 'nd'; break;
        case 3: suffix = 'rd'; break;
      }
    }
    
    final month = DateFormat('MMMM').format(date);
    return '$day$suffix $month ${date.year != now.year ? date.year : ''}'.trim();
  }
}

class _TimeFilterChip extends StatelessWidget {
  final String label;
  final TimeRange range;
  final bool selected;
  final VoidCallback onTap;

  const _TimeFilterChip({
    required this.label,
    required this.range,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}
