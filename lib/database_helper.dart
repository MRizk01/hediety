// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// class Gift {
//   int? id;
//   String name;
//   String description;
//   String category;
//   double price;

//   Gift({this.id, required this.name, required this.description, required this.category, required this.price});

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'category': category,
//       'price': price,
//     };
//   }

//   static Gift fromMap(Map<String, dynamic> map) {
//     return Gift(
//       id: map['id'],
//       name: map['name'],
//       description: map['description'],
//       category: map['category'],
//       price: map['price'],
//     );
//   }
// }

// class DatabaseHelper {
//   static Database? _database;

//   Future<Database> get database async {
//     if (_database != null) return _database!;

//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     final databasePath = await getDatabasesPath();
//     final path = join(databasePath, 'hedieaty.db');

//     return openDatabase(path, onCreate: _createDb, version: 1);
//   }

//   Future<void> _createDb(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE gifts(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         name TEXT,
//         description TEXT,
//         category TEXT,
//         price REAL
//       )
//     ''');
//   }

//   Future<int> insertGift(Gift gift) async {
//     final db = await database;
//     return await db.insert('gifts', gift.toMap());
//   }

//   Future<List<Gift>> getGifts() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query('gifts');
//     return List.generate(maps.length, (i) {
//       return Gift.fromMap(maps[i]);
//     });
//   }

//   Future<int> updateGift(Gift gift) async {
//     final db = await database;
//     return await db.update('gifts', gift.toMap(), where: 'id = ?', whereArgs: [gift.id]);
//   }

//   Future<int> deleteGift(int id) async {
//     final db = await database;
//     return await db.delete('gifts', where: 'id = ?', whereArgs: [id]);
//   }
// }