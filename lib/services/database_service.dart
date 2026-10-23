import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, 'resq_mitra.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT NOT NULL,
            profile_json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE emergency_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            description TEXT,
            latitude REAL,
            longitude REAL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<int> saveProfile(String role, String json) async {
    final db = await database;
    return db.insert('profiles', {
      'role': role,
      'profile_json': json,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> saveEmergencyRequest({
    required String category,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    return db.insert('emergency_requests', {
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'submitted_demo',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
