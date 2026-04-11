import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../models/category.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';
import '../widgets/budget_progress_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final budProv = context.watch<BudgetProvider>();
    final total = expProv.monthlyTotal;
    final topCat = expProv.topCategory;
    final overCat = expProv.overspendingCategory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Top greeting + header card ──────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.headerGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting row
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              image: const DecorationImage(
                                image: AssetImage('assets/images/app_icon.png'),
                                fit: BoxFit.cover,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hello there! 👋',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('YOUR BALANCE THIS MONTH',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs. ${total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Icon(Icons.visibility_outlined,
                                      color: Colors.white54, size: 18),
                                ),
                              ],
                            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                            const SizedBox(height: 16),
                            BudgetProgressBar(
                              spent: total,
                              limit: budProv.monthlyLimit,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _QuickAction(
                              icon: Icons.swap_horiz_rounded, label: 'Transfer'),
                          _QuickAction(icon: Icons.download_rounded, label: 'Income'),
                          _QuickAction(
                              icon: Icons.pie_chart_outline_rounded, label: 'Stats'),
                          _QuickAction(
                              icon: Icons.add_rounded, label: 'Add'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Rainbow accent line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.rainbowGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Financial insight banner ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (overCat != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('💡',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Let's check your Financial Insight – overspending on $overCat!",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.primary),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                  if (topCat != null) ...[
                    const SizedBox(height: 12),
                    _TopCategoryRow(topCat: topCat, expProv: expProv),
                  ],
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Recent Transactions header ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 17)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See all',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          // ── Transactions list ────────────────────────────────────────────
          expProv.expenses.isEmpty
              ? SliverToBoxAdapter(
                  child: _EmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final exp = expProv.expenses
                            .take(10)
                            .toList()[index];
                        return _TransactionTile(expense: exp,
                            onDelete: () =>
                                expProv.deleteExpense(exp.id))
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: 50 * index),
                                duration: 300.ms);
                      },
                      childCount: expProv.expenses.length > 10
                          ? 10
                          : expProv.expenses.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TopCategoryRow extends StatelessWidget {
  final String topCat;
  final ExpenseProvider expProv;
  const _TopCategoryRow({required this.topCat, required this.expProv});

  @override
  Widget build(BuildContext context) {
    final cat = ExpenseCategory.fromString(topCat);
    final total = expProv.categoryBreakdown[topCat] ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.categoryColor(topCat).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Category',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500)),
              Text(cat.label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
          const Spacer(),
          Text('Rs. ${total.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.categoryColor(topCat))),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic expense;
  final VoidCallback onDelete;
  const _TransactionTile({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cat = ExpenseCategory.fromString(expense.category);
    final color = AppTheme.categoryColor(expense.category);
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.danger),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(cat.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 2),
                  Text(
                    expense.note?.isNotEmpty == true
                        ? expense.note!
                        : DateFormat('d MMM yyyy')
                            .format(expense.date),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${expense.amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('No transactions yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add\nyour first expense',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
