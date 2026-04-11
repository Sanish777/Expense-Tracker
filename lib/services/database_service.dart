import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/app_category.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String dbName = 'wise_expense.db';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wise_expense.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses(
            id TEXT PRIMARY KEY,
            amount REAL,
            category TEXT,
            date TEXT,
            note TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE budgets(
            id TEXT PRIMARY KEY,
            monthlyLimit REAL,
            dailyLimit REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE users(
            username TEXT PRIMARY KEY,
            password_hash TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE categories(
            id TEXT PRIMARY KEY,
            title TEXT,
            emoji TEXT
          )
        ''');

        // Seed admin user
        await db.insert('users', {
          'username': 'admin',
          'password_hash': '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918' // admin123
        });

        // Seed default categories
        final defaultCategories = [
          {'id': 'food', 'title': 'Food', 'emoji': '🍔'},
          {'id': 'transport', 'title': 'Transport', 'emoji': '🚌'},
          {'id': 'shopping', 'title': 'Shopping', 'emoji': '🛒'},
          {'id': 'bills', 'title': 'Bills', 'emoji': '💡'},
          {'id': 'entertainment', 'title': 'Entertainment', 'emoji': '🎬'},
          {'id': 'others', 'title': 'Others', 'emoji': '📦'},
        ];
        for (var cat in defaultCategories) {
          await db.insert('categories', cat);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE categories(
              id TEXT PRIMARY KEY,
              title TEXT,
              emoji TEXT
            )
          ''');
          // Seed default categories for existing users
          final defaultCategories = [
            {'id': 'food', 'title': 'Food', 'emoji': '🍔'},
            {'id': 'transport', 'title': 'Transport', 'emoji': '🚌'},
            {'id': 'shopping', 'title': 'Shopping', 'emoji': '🛒'},
            {'id': 'bills', 'title': 'Bills', 'emoji': '💡'},
            {'id': 'entertainment', 'title': 'Entertainment', 'emoji': '🎬'},
            {'id': 'others', 'title': 'Others', 'emoji': '📦'},
          ];
          for (var cat in defaultCategories) {
            await db.insert('categories', cat);
          }
        }
        if (oldVersion < 3) {
          // Rename passwordHash to password_hash if it exists
          try {
            await db.execute('ALTER TABLE users RENAME COLUMN passwordHash TO password_hash');
          } catch (e) {
            // If RENAME COLUMN is not supported, we migrate manually
            final users = await db.query('users');
            await db.execute('DROP TABLE users');
            await db.execute('''
              CREATE TABLE users(
                username TEXT PRIMARY KEY,
                password_hash TEXT
              )
            ''');
            for (var user in users) {
              await db.insert('users', {
                'username': user['username'],
                'password_hash': user['passwordHash'] ?? user['password_hash'],
              });
            }
          }
        }
      },
    );
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<AppCategory>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => AppCategory.fromMap(maps[i]));
  }

  Future<void> insertCategory(AppCategory category) async {
    final db = await database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // ── Auth Methods ──────────────────────────────────────────────────────────

  Future<bool> verifyPassword(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isEmpty) return false;
    final storedHash = maps.first['password_hash'] as String;
    return storedHash == _hashPassword(password);
  }

  Future<void> updatePassword(String username, String newPassword) async {
    final db = await database;
    await db.update(
      'users',
      {'password_hash': _hashPassword(newPassword)},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // ── Expense CRUD ──────────────────────────────────────────────────────────

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('budgets');
  }

  // ── Budget CRUD ───────────────────────────────────────────────────────────

  Future<void> saveBudget(Budget budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      {
        'id': 'current',
        'monthlyLimit': budget.monthlyLimit,
        'dailyLimit': budget.dailyLimit,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Budget?> getBudget() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: ['current'],
    );
    if (maps.isEmpty) return null;
    return Budget(
      monthlyLimit: maps.first['monthlyLimit'],
      dailyLimit: maps.first['dailyLimit'],
    );
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'];
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<File> getDatabaseFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(join(docsDir.path, dbName));
  }
}
