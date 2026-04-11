import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/budget.dart';

class HiveService {
  static const String _expenseBoxName = 'expenses';
  static const String _budgetBoxName = 'budgets';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(BudgetAdapter());
    await Hive.openBox<Expense>(_expenseBoxName);
    await Hive.openBox<Budget>(_budgetBoxName);
  }

  // ── Expense CRUD ──────────────────────────────────────────────────────────

  Box<Expense> get _expenseBox => Hive.box<Expense>(_expenseBoxName);

  Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
  }

  List<Expense> getAllExpenses() {
    return _expenseBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> getExpensesByMonth(DateTime month) {
    return _expenseBox.values
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ── Budget CRUD ───────────────────────────────────────────────────────────

  Box<Budget> get _budgetBox => Hive.box<Budget>(_budgetBoxName);

  Future<void> saveBudget(Budget budget) async {
    await _budgetBox.put('current', budget);
  }

  Budget? getBudget() {
    return _budgetBox.get('current');
  }

  Future<void> clearAll() async {
    await _expenseBox.clear();
    await _budgetBox.clear();
  }
}
