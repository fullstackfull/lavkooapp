import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HealthDatabaseHelper {
  static final HealthDatabaseHelper instance = HealthDatabaseHelper._init();
  static Database? _database;

  HealthDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const intType = 'INTEGER';
    const realType = 'REAL';

    // Daily summary table (one row per day)
    await db.execute('''
    CREATE TABLE daily_health_summary (
      date $textType PRIMARY KEY,
      water_ml $intType DEFAULT 0,
      sleep_hrs $realType DEFAULT 0.0,
      mood_score $intType DEFAULT 0,
      steps $intType DEFAULT 0,
      calories $intType DEFAULT 0,
      weight_kg $realType DEFAULT 0.0,
      health_score $realType DEFAULT 0.0
    )
    ''');

    // Historical records table (multiple entries per day allowed, e.g. BP, Sugar)
    await db.execute('''
    CREATE TABLE health_records_history (
      id $idType,
      timestamp $textType NOT NULL,
      record_type $textType NOT NULL,
      value1 $realType,
      value2 $realType,
      notes $textType
    )
    ''');
  }

  // --- Daily Summary Operations ---

  /// Get summary for a specific date (YYYY-MM-DD)
  Future<Map<String, dynamic>?> getDailySummary(String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_health_summary',
      columns: null,
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  /// Create or update daily summary
  Future<int> updateDailySummary(String date, Map<String, dynamic> data) async {
    final db = await instance.database;
    final existing = await getDailySummary(date);
    
    if (existing != null) {
      return await db.update(
        'daily_health_summary',
        data,
        where: 'date = ?',
        whereArgs: [date],
      );
    } else {
      data['date'] = date;
      return await db.insert('daily_health_summary', data);
    }
  }

  // Helper to update specific column in daily summary safely
  Future<void> updateDailyMetric(String date, String column, dynamic value) async {
    final db = await instance.database;
    final existing = await getDailySummary(date);
    if (existing != null) {
      await db.update(
        'daily_health_summary',
        {column: value},
        where: 'date = ?',
        whereArgs: [date],
      );
    } else {
      await db.insert(
        'daily_health_summary',
        {'date': date, column: value},
      );
    }
    // Automatically recalculate score after any update
    await recalculateHealthScore(date);
  }

  // --- Historical Records Operations ---

  Future<int> insertRecord(String type, double val1, {double? val2, String? notes}) async {
    final db = await instance.database;
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'record_type': type,
      'value1': val1,
      'value2': val2,
      'notes': notes ?? '',
    };
    return await db.insert('health_records_history', data);
  }

  Future<List<Map<String, dynamic>>> getRecordsByType(String type) async {
    final db = await instance.database;
    return await db.query(
      'health_records_history',
      where: 'record_type = ?',
      whereArgs: [type],
      orderBy: 'timestamp DESC',
    );
  }

  // --- Health Score Calculation ---
  Future<void> recalculateHealthScore(String date) async {
    final summary = await getDailySummary(date);
    if (summary == null) return;

    double water = (summary['water_ml'] as num?)?.toDouble() ?? 0.0;
    double sleep = (summary['sleep_hrs'] as num?)?.toDouble() ?? 0.0;
    double mood = (summary['mood_score'] as num?)?.toDouble() ?? 0.0;
    double steps = (summary['steps'] as num?)?.toDouble() ?? 0.0;

    double score = 0.0; // Starts at 0% when no metrics are tracked

    // Water: Goal 2500ml -> up to 25 pts
    if (water >= 2500) score += 25;
    else if (water > 0) score += (water / 2500) * 25;

    // Sleep: Goal 7-8 hrs -> up to 25 pts
    if (sleep >= 7) score += 25;
    else if (sleep > 0) score += (sleep / 7) * 25;

    // Mood: Goal 7-10 -> up to 25 pts
    if (mood >= 7) score += 25;
    else if (mood > 0) score += (mood / 10) * 25;

    // Steps: Goal 8000 -> up to 25 pts
    if (steps >= 8000) score += 25;
    else if (steps > 0) score += (steps / 8000) * 25;

    score = score.clamp(0, 100);

    final db = await instance.database;
    await db.update(
      'daily_health_summary',
      {'health_score': score},
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
