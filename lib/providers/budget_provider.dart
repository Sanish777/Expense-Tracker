import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../services/database_service.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseService _db;

  Budget? _budget;

  BudgetProvider(this._db) {
    _load();
  }

  Budget? get budget => _budget;
  double get monthlyLimit => _budget?.monthlyLimit ?? 0;
  double get dailyLimit => _budget?.dailyLimit ?? 0;

  Future<void> _load() async {
    _budget = await _db.getBudget();
    notifyListeners();
  }

  Future<void> saveBudget({
    required double monthlyLimit,
    required double dailyLimit,
  }) async {
    final budget = Budget(monthlyLimit: monthlyLimit, dailyLimit: dailyLimit);
    await _db.saveBudget(budget);
    _budget = budget;
    notifyListeners();
  }
}
