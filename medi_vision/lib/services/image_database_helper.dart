import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ImageDatabaseHelper {
  static final ImageDatabaseHelper _instance = ImageDatabaseHelper._internal();

  factory ImageDatabaseHelper() => _instance;

  ImageDatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'images.db');
    return await openDatabase(
      path,
      version: 2, // Increment version to force re-creation
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE scanned_images(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          path TEXT NOT NULL,
          userId TEXT NOT NULL
        )''');
      },
    );
  }

  // Insert image with userId
  Future<void> insertImage(String imagePath, String userId) async {
    final db = await database;
    await db.insert('scanned_images', {
      'path': imagePath,
      'userId': userId,  // Store the userId with the image
    });
  }

  // Fetch images per userId
  Future<List<String>> getImagesForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scanned_images',
      where: 'userId = ?',
      whereArgs: [userId],  // Fetch images for this user only
    );
    return maps.map((e) => e['path'] as String).toList();
  }
}
