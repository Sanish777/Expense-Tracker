import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/expense_card.dart';
import '../widgets/category_chip.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final expenses = expProv.filteredExpenses;
    final selected = expProv.categoryFilter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Category filter row ─────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              children: [
                // "All" chip
                GestureDetector(
                  onTap: () => expProv.setCategoryFilter(null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      gradient:
                          selected == null ? AppTheme.primaryGradient : null,
                      color: selected == null
                          ? null
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '✨ All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected == null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected == null ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
                ...ExpenseCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: CategoryChip(
                        category: cat,
                        isSelected: selected == cat.name,
                        onTap: () => expProv.setCategoryFilter(
                            selected == cat.name ? null : cat.name),
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
                        const Text(
                          'Try a different filter',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 13),
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
