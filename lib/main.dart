import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Gift Model and DatabaseHelper (same as before)
class Gift {
  int? id;
  String name;
  String description;
  String category;
  double price;

  Gift({this.id, required this.name, required this.description, required this.category, required this.price});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
    };
  }

  static Gift fromMap(Map<String, dynamic> map) {
    return Gift(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: map['price'],
    );
  }
}

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'hedieaty.db');

    return openDatabase(path, onCreate: _createDb, version: 1);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE gifts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        category TEXT,
        price REAL
      )
    ''');
  }

  Future<int> insertGift(Gift gift) async {
    final db = await database;
    return await db.insert('gifts', gift.toMap());
  }

  Future<List<Gift>> getGifts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('gifts');
    return List.generate(maps.length, (i) => Gift.fromMap(maps[i]));
  }

  Future<int> updateGift(Gift gift) async {
    final db = await database;
    return await db.update('gifts', gift.toMap(), where: 'id = ?', whereArgs: [gift.id]);
  }

  Future<int> deleteGift(int id) async {
    final db = await database;
    return await db.delete('gifts', where: 'id = ?', whereArgs: [id]);
  }
}

// UI Code (GiftListPage and GiftDetailsPage)
class GiftListPage extends StatefulWidget {
  const GiftListPage({super.key});

  @override
  State<GiftListPage> createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final dbHelper = DatabaseHelper();
  List<Gift> gifts = [];

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  _loadGifts() async {
    gifts = await dbHelper.getGifts();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gift List')),
      body: ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return ListTile(
            title: Text(gift.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GiftDetailsPage(gift: gift)),
              ).then((_) => _loadGifts()); // Refresh list after returning
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GiftDetailsPage()),
              );
              _loadGifts(); // Refresh list after adding
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () async {
              if (gifts.isNotEmpty) {
                await dbHelper.deleteGift(gifts.last.id!);
                _loadGifts();
              }
            },
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}

class GiftDetailsPage extends StatefulWidget {
  final Gift? gift;
  const GiftDetailsPage({super.key, this.gift});

  @override
  State<GiftDetailsPage> createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.gift != null) {
      nameController.text = widget.gift!.name;
      descriptionController.text = widget.gift!.description;
      categoryController.text = widget.gift!.category;
      priceController.text = widget.gift!.price.toString();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gift == null ? 'Add Gift' : 'Edit Gift'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final gift = Gift(
                      id: widget.gift?.id,
                      name: nameController.text,
                      description: descriptionController.text,
                      category: categoryController.text,
                      price: double.parse(priceController.text),
                    );
                    final dbHelper = DatabaseHelper();
                    if (widget.gift == null) {
                      await dbHelper.insertGift(gift);
                    } else {
                      await dbHelper.updateGift(gift);
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const HedieatyApp());
}

class HedieatyApp extends StatelessWidget {
  const HedieatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<String> friends = const ['Alice', 'Bob', 'Charlie'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hedieaty Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GiftListPage()),
            );
          },
          child: const Text('View Gift List'),
        ),
      ),
    );
  }
}