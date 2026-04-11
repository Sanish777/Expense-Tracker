import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/app_category.dart';
import '../services/database_service.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<AppCategory> _categories = [];
  bool _isLoading = false;

  CategoryProvider(this._db) {
    _load();
  }

  List<AppCategory> get categories => _categories;
  bool get isLoading => _isLoading;

  AppCategory? findById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    _categories = await _db.getCategories();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String title, String emoji) async {
    final category = AppCategory(
      id: const Uuid().v4(),
      title: title,
      emoji: emoji,
    );
    await _db.insertCategory(category);
    await _load();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await _load();
  }
}
