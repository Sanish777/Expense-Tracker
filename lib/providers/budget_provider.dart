import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../services/hive_service.dart';

class BudgetProvider extends ChangeNotifier {
  final HiveService _hive;

  Budget? _budget;

  BudgetProvider(this._hive) {
    _load();
  }

  Budget? get budget => _budget;
  double get monthlyLimit => _budget?.monthlyLimit ?? 0;
  double get dailyLimit => _budget?.dailyLimit ?? 0;

  void _load() {
    _budget = _hive.getBudget();
    notifyListeners();
  }

  Future<void> saveBudget({
    required double monthlyLimit,
    required double dailyLimit,
  }) async {
    final budget = Budget(monthlyLimit: monthlyLimit, dailyLimit: dailyLimit);
    await _hive.saveBudget(budget);
    _budget = budget;
    notifyListeners();
  }
}
