import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PlateDatabase {
  static final PlateDatabase instance = PlateDatabase._init();
  static Database? _database;

  PlateDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('plates.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plate TEXT NOT NULL
      )
    ''');
  }

  // CREATE
  Future<bool> insertPlate(String plate) async {
    final db = await database;

    final exists = await plateExists(plate);
    if (exists) return false;

    await db.insert('plates', {'plate': plate});

    return true;
  }

  // READ
  Future<List<String>> getPlates() async {
    final db = await instance.database;
    final result = await db.query('plates');
    return result.map((e) => e['plate'] as String).toList();
  }

  // DELETE
  Future<void> deletePlate(String plate) async {
    final db = await instance.database;
    await db.delete('plates', where: 'plate = ?', whereArgs: [plate]);
  }

  //UPDATE
  Future<void> updatePlate(String oldPlate, String newPlate) async {
    final db = await database;

    await db.update(
      'plates',
      {'plate': newPlate},
      where: 'plate = ?',
      whereArgs: [oldPlate],
    );
  }

  //EXISTS
  Future<bool> plateExists(String plate) async {
    final db = await database;

    final res = await db.query(
      'plates',
      where: 'plate = ?',
      whereArgs: [plate],
      limit: 1,
    );

    return res.isNotEmpty;
  }
}
