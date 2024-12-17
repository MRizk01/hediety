import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


// Gift Model and DatabaseHelper
// Removed duplicate Gift class definition



class Gift {
  String? id;
  String name;
  String description;
  String category;
  double price;
  String status;

  Gift({this.id, required this.name, required this.description, required this.category, required this.price,required this.status});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
    };
  }

  static Gift fromFirestore(Map<String, dynamic> map, String id) {
    return Gift(
      id: id,
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: (map['price'] as num).toDouble(),
      status: map['status'] ?? 'available',
    );
  }

  static Gift fromSQLite(Map<String, dynamic> map) {
    return Gift(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: map['price'],
      status: map['status'],
    );
  }




}

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
    final path = join(dbPath, 'gifts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE gifts(
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            category TEXT,
            price REAL,
            status TEXT,
            isSynced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> insertGift(Gift gift, {bool synced = false}) async {
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
        'isSynced': synced ? 1 : 0
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Gift>> getAllGifts() async {
    final db = await database;
    final result = await db.query('gifts');
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
}

  Future<void> syncLocalToFirestore() async {
    final dbHelper = DatabaseHelper();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final unsyncedGifts = await dbHelper.getAllGifts();
      for (var gift in unsyncedGifts) {
        //check if the gift is not synced and has an id
        if(gift.id == null || gift.id!.isEmpty){
          // Add to Firestore
          final docRef = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('gifts')
              .add(gift.toMap());

          // Update SQLite with Firestore ID
          gift.id = docRef.id;
          await dbHelper.insertGift(gift, synced: true);
        }
      }
    }
  }

// LoginPage
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      // Navigate to Gift List screen after successful login
                    } on FirebaseAuthException catch (e) {
                      // Handle login errors (e.g., wrong credentials)
                    }
                  }
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Navigate to RegistrationPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationPage()),
                  );
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// RegistrationPage
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      UserCredential userCredential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      // Navigate to the next screen or show a success message
                      if (userCredential.user != null) {
                        Navigator.pop(context); // Return to previous screen
                      }
                    } on FirebaseAuthException catch (e) {
                      String errorMessage = "Registration failed.";
                      if (e.code == 'weak-password') {
                        errorMessage = 'The password provided is too weak.';
                      } else if (e.code == 'email-already-in-use') {
                        errorMessage = 'The account already exists for that email.';
                      } else if (e.code == 'invalid-email') {
                        errorMessage = 'The email address is not valid.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('An unexpected error occurred.')),
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// UI Code (GiftListPage and GiftDetailsPage)
class GiftListPage extends StatefulWidget {
  const GiftListPage({super.key});

  @override
  State<GiftListPage> createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  // final dbHelper = DatabaseHelper();
  List<Gift> gifts = [];
  late DatabaseReference _giftsRef;
  late StreamSubscription<DatabaseEvent> _giftsSubscription;
  
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _giftsRef = FirebaseDatabase.instance.ref('users/${user.uid}/gifts');
      _fetchAndSyncGifts();
      syncLocalToFirestore(); // Sync local changes to Firestore
    }
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncLocalToFirestore(); // Trigger sync when back online
      }
    });

  }

  void _fetchAndSyncGifts() async {
    final dbHelper = DatabaseHelper();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final giftsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('gifts');

      giftsRef.snapshots().listen((QuerySnapshot snapshot) async {
        for (var doc in snapshot.docs) {
          final gift = Gift.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);

          // Insert only if the gift does not already exist in SQLite
          final existingGifts = await dbHelper.getAllGifts();
          final exists = existingGifts.any((g) => g.id == gift.id);

          if (!exists) {
            await dbHelper.insertGift(gift, synced: true);
          }
        }

        _loadGiftsFromSQLite(); // Refresh the UI
      });
    }
  }

  void _loadGiftsFromSQLite() async {
    final dbHelper = DatabaseHelper();
    final loadedGifts = await dbHelper.getAllGifts();
    setState(() {
      gifts = loadedGifts;
    });
  }



  @override
  void dispose() {
    _giftsSubscription.cancel();
    super.dispose();
  }  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
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
              );
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
              // _loadGifts(); // Refresh list after adding
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () async {
              if (gifts.isNotEmpty) {
                final lastGiftId = gifts.last.id;
                final user = FirebaseAuth.instance.currentUser;

                if (lastGiftId != null && user != null) {
                  // Delete from Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('gifts')
                      .doc(lastGiftId)
                      .delete();

                  // Delete from SQLite
                  final dbHelper = DatabaseHelper();
                  await dbHelper.deleteGift(lastGiftId);

                  setState(() {
                    gifts.removeWhere((gift) => gift.id == lastGiftId);
                  });
                }
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
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  String _selectedStatus = "available";
  
  @override
  void initState() {
    super.initState();
    if (widget.gift != null) {
      nameController.text = widget.gift!.name;
      descriptionController.text = widget.gift!.description;
      categoryController.text = widget.gift!.category;
      priceController.text = widget.gift!.price.toString();
      _selectedStatus = widget.gift!.status;
    }

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncLocalToFirestore(); // Trigger sync when back online
      }
    });    
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
        title: const Text('Gift Details'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: ['available', 'Pending', 'Completed'].map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    // Prepare the Gift data
                    final newGift = Gift(
                      name: nameController.text,
                      description: descriptionController.text,
                      category: categoryController.text,
                      price: double.tryParse(priceController.text) ?? 0.0,
                      status: _selectedStatus,
                    );

                    // Add the Gift to Firestore
                    final docRef = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('gifts')
                        .add(newGift.toMap());

                    // Use Firestore's generated ID
                    newGift.id = docRef.id;

                    // Cache the new Gift in SQLite
                    final dbHelper = DatabaseHelper();
                    await dbHelper.insertGift(newGift, synced: true);

                    Navigator.pop(context); // Return to the previous screen
                  }
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

Future<bool> isOnline() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const GiftListPage();
        }
        return LoginPage();
      },
    );
  }
}