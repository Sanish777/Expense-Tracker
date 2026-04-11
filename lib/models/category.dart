enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  entertainment,
  others;

  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.others:
        return 'Others';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.food:
        return '🍔';
      case ExpenseCategory.transport:
        return '🚌';
      case ExpenseCategory.shopping:
        return '🛒';
      case ExpenseCategory.bills:
        return '💡';
      case ExpenseCategory.entertainment:
        return '🎬';
      case ExpenseCategory.others:
        return '📦';
    }
  }

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ExpenseCategory.others,
    );
  }
}
