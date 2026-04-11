import '../providers/category_provider.dart';
import '../models/app_category.dart';
import '../widgets/expense_card.dart';
import '../widgets/category_chip.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final catProv = context.watch<CategoryProvider>();
    final expenses = expProv.filteredExpenses;
    final selected = expProv.categoryFilter;

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
            child: expenses.isEmpty
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
                    itemCount: expenses.length,
                    itemBuilder: (context, i) {
                      return ExpenseCard(
                        expense: expenses[i],
                        onDelete: () =>
                            expProv.deleteExpense(expenses[i].id),
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: 40 * i),
                          duration: 300.ms);
                    },
                  ),
          ),
        ],
      ),
    );
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
