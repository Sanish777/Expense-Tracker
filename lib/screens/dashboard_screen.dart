import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../models/app_category.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';
import '../widgets/budget_progress_bar.dart';
import '../screens/add_expense_screen.dart';
import '../screens/insights_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceVisible = true;

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action feature coming soon! 🚀'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final budProv = context.watch<BudgetProvider>();
    final catProv = context.watch<CategoryProvider>();
    
    final total = expProv.monthlyTotal;
    final topCat = expProv.topCategory;
    
    final overCatId = expProv.overspendingCategory;
    final overCatTitle = overCatId != null 
        ? (catProv.findById(overCatId)?.title ?? overCatId) 
        : null;

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
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting row (Profile Image Removed)
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hello there! 👋',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              context.read<ExpenseProvider>().triggerWeeklySummary();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Testing local notification...', style: TextStyle(color: Colors.white)),
                                  backgroundColor: AppTheme.accent,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('YOUR BALANCE THIS MONTH',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    _isBalanceVisible 
                                        ? 'Rs. ${total.toStringAsFixed(0)}'
                                        : 'Rs. •••••••',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isBalanceVisible 
                                        ? Icons.visibility_outlined 
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                                ),
                              ],
                            ).animate().fadeIn(duration: 500.ms),
                            const SizedBox(height: 20),
                            BudgetProgressBar(
                              spent: total,
                              limit: budProv.monthlyLimit,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _QuickAction(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Transfer',
                            onTap: () => _showComingSoon(context, 'Transfer'),
                          ),
                          _QuickAction(
                            icon: Icons.download_rounded,
                            label: 'Income',
                            onTap: () => _showComingSoon(context, 'Income'),
                          ),
                          _QuickAction(
                            icon: Icons.pie_chart_outline_rounded,
                            label: 'Stats',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InsightsScreen()),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.add_rounded,
                            label: 'Add',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                            ),
                          ),
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
                  if (overCatId != null)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InsightsScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
                                "Let's check your Financial Insight – overspending on $overCatTitle!",
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
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}

class _TopCategoryRow extends StatelessWidget {
  final String topCat;
  final ExpenseProvider expProv;
  const _TopCategoryRow({required this.topCat, required this.expProv});

  @override
  Widget build(BuildContext context) {
    final catProv = context.watch<CategoryProvider>();
    final cat = catProv.findById(topCat);
    final total = expProv.categoryBreakdown[topCat] ?? 0;
    final color = AppTheme.primary;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(cat?.emoji ?? '📦', style: const TextStyle(fontSize: 20)),
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
              Text(cat?.title ?? 'Unknown',
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
                  color: color)),
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
    final catProv = context.watch<CategoryProvider>();
    final cat = catProv.findById(expense.category);
    final color = AppTheme.primary;

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
                child: Text(cat?.emoji ?? '📦',
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat?.title ?? 'Unknown',
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
