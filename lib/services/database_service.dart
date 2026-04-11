import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/expense.dart';
import '../models/budget.dart';

class DatabaseService {
  static Database? _db;
  static const String dbName = 'spendwise.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Expenses table
        await db.execute('''
          CREATE TABLE expenses(
            id TEXT PRIMARY KEY,
            amount REAL,
            category TEXT,
            date TEXT,
            note TEXT
          )
        ''');

        // Budget table
        await db.execute('''
          CREATE TABLE budgets(
            id TEXT PRIMARY KEY,
            monthlyLimit REAL,
            dailyLimit REAL
          )
        ''');

        // Settings table
        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        // Users table (for Auth)
        await db.execute('''
          CREATE TABLE users(
            username TEXT PRIMARY KEY,
            password_hash TEXT,
            is_admin INTEGER
          )
        ''');

        // Seed admin user
        final adminPassHash = _hashPassword('admin123');
        await db.insert('users', {
          'username': 'admin',
          'password_hash': adminPassHash,
          'is_admin': 1,
        });
      },
    );
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
