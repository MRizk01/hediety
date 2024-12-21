import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_db;
import '../models/event.dart';
import '../models/gift.dart';
import '../models/friend.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = path_db.join(dbPath, 'hedieaty.db');

    return await openDatabase(
      path,
      version: 3,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE events(
          id TEXT PRIMARY KEY,
          name TEXT,
          date TEXT,
          location TEXT,
          description TEXT,
          user_id TEXT
        )
      ''');      
      await db.execute('''
        CREATE TABLE gifts(
          id TEXT PRIMARY KEY,
          name TEXT,
          description TEXT,
          category TEXT,
          price REAL,
          status TEXT,
          event_id TEXT,   -- Foreign key to associate with events
          user_id TEXT,
          isSynced INTEGER DEFAULT 0
        )
      ''');
        // Create friends table
        db.execute('''
          CREATE TABLE friends(
            id TEXT PRIMARY KEY,
            name TEXT,
            phoneNumber TEXT,
            user_id TEXT
          )
        ''');
      },
       onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 3) {
        await db.execute('''
          CREATE TABLE events(
            id TEXT PRIMARY KEY,
            name TEXT,
            date TEXT,
            location TEXT,
            description TEXT,
            user_id TEXT
          )
        ''');   
        await db.execute('ALTER TABLE gifts ADD COLUMN event_id TEXT');
      }
    },
  );
}

Future<void> insertGift(Gift gift, String userId, {bool synced = false}) async {
  final db = await database;
  await db.insert(
    'gifts',
    {
      'id': gift.id,
      'name': gift.name,
      'description': gift.description,
      'category': gift.category,
      'price': gift.price,
      'status': gift.status,
      'event_id': gift.eventId, // Store event ID
      'user_id': userId,
      'isSynced': synced ? 1 : 0,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Gift>> getGiftsByEvent(String eventId) async {
  final db = await database;
  final result = await db.query('gifts', where: 'event_id = ?', whereArgs: [eventId]);
  return result.map((map) => Gift.fromSQLite(map)).toList();
}


  Future<List<Gift>> getAllGifts(String userId) async {
    final db = await database;
    final result = await db.query('gifts', where: 'user_id = ?', whereArgs: [userId]);
    return result.map((map) => Gift.fromSQLite(map)).toList();
}

  Future<void> deleteGift(String id) async {
    final db = await database;
    await db.delete('gifts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'gifts',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// Friend methods
   Future<void> insertFriend(Friend friend, String userId) async {
     final db = await database;
      await db.insert(
        'friends',
        {
          'id': friend.id,
          'name': friend.name,
          'phoneNumber': friend.phoneNumber,
          'user_id': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    Future<List<Friend>> getAllFriends(String userId) async {
      final db = await database;
      final result = await db.query('friends', where: 'user_id = ?', whereArgs: [userId]);
      return result.map((map) => Friend.fromSQLite(map)).toList();
    }


   Future<void> deleteFriend(String id) async {
      final db = await database;
      await db.delete('friends', where: 'id = ?', whereArgs: [id]);
   }

  Future<void> insertEvent(Event event, String userId) async {
    final db = await database;
    await db.insert(
      'events',
      {
        'id': event.id,
        'name': event.name,
        'date': event.date,
        'location': event.location,
        'description': event.description,
        'user_id': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Event>> getAllEvents(String userId) async {
    final db = await database;
    final result = await db.query('events', where: 'user_id = ?', whereArgs: [userId]);
    return result.map((map) => Event.fromSQLite(map)).toList();
  }

  Future<void> deleteEvent(String eventId) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [eventId]);
    await db.delete('gifts', where: 'event_id = ?', whereArgs: [eventId]); // Cascade delete
  }
}