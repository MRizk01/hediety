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


Future<void> syncLocalToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final dbHelper = DatabaseHelper();    
    final unsyncedGifts = await dbHelper.getAllGifts(user.uid);
    for (var gift in unsyncedGifts) {
      //check if the gift is not synced and has an id
      if(gift.id == null || gift.id!.isEmpty){
        // Add to Firestore
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('gifts')
            .add(gift.toMap());
        gift.id = docRef.id;
        await dbHelper.insertGift(gift, user.uid, synced: true);
      }
    }
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
    final path = join(dbPath, 'hedieaty.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE gifts(
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            category TEXT,
            price REAL,
            status TEXT,
            user_id TEXT,   -- Add user_id field
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
        if (oldVersion < 3) {  // Increment version number
          await db.execute('ALTER TABLE gifts ADD COLUMN user_id TEXT');
        }
      }
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
        'user_id': userId,  // Store user ID
        'isSynced': synced ? 1 : 0
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
}

class Friend {
  String? id;
  String name;
  String phoneNumber;
  // String? profilePictureUrl; // For later use

  Friend({this.id, required this.name, required this.phoneNumber,});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  static Friend fromSQLite(Map<String, dynamic> map) {
    return Friend(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
    );
  }

  static Friend fromFirestore(Map<String, dynamic> map, String id) {
    return Friend(
      id: id,
      name: map['name'],
      phoneNumber: map['phoneNumber'],
    );
  }
}

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

////////////
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController phoneController = TextEditingController();

  Future<void> addFriend(String phoneNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Search for the user with the entered phone number
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .get();

      if (query.docs.isNotEmpty) {
        final friendData = query.docs.first;
        final friendUid = friendData.id; // The friend's UID
        final friendName = friendData['name'];

        // Add the friend to the current user's friends list
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('friends')
            .doc(friendUid)
            .set({
          'name': friendName,
          'phone': phoneNumber,
        });

        print('Friend added successfully!');
      } else {
        print('User with this phone number does not exist.');
      }
    } catch (e) {
      print('Failed to add friend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Friend\'s Phone Number',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await addFriend(phoneController.text);
                Navigator.pop(context);
              },
              child: const Text('Add Friend'),
            ),
          ],
        ),
      ),
    );
  }
}





// LoginPage
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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
                      //cc1
                      // Navigator.pushReplacement(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => const HomePage()),
                      // );                      
                      // Navigate to Gift List screen after successful login
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message ?? 'Login failed')),
                      );                      
                      // Handle login errors (e.g., wrong credentials)
                    }
                  }
                },
                child: const Text('Login'),
              ),
              
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
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

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
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
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
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userCredential.user!.uid)
                            .set({
                          'name': nameController.text, // Replace with actual name input
                          'phone': phoneController.text, // Replace with an input for phone number
                        });
                      }
                      Navigator.pop(context);
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
          final existingGifts = await dbHelper.getAllGifts(user.uid);
          final exists = existingGifts.any((g) => g.id == gift.id);

          if (!exists) {
            await dbHelper.insertGift(gift, user.uid, synced: true);
          }
        }

        _loadGiftsFromSQLite(); // Refresh the UI
      });
    }
  }

void _loadGiftsFromSQLite() async {
  final dbHelper = DatabaseHelper();
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final loadedGifts = await dbHelper.getAllGifts(user.uid);
    setState(() {
      gifts = loadedGifts;
    });
  }
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



class FriendGiftListPage extends StatelessWidget {
  final String friendId;
  const FriendGiftListPage({super.key, required this.friendId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend\'s Gift List')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .collection('gifts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No gifts available.'));
          }

          final gifts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];
              return ListTile(
                title: Text(gift['name']),
                subtitle: Text(gift['description']),
              );
            },
          );
        },
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
                    await dbHelper.insertGift(newGift, user.uid, synced: true);

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
      // cc2
      // home: const AuthGate(),
      home: const AuthGate(),
    );
  }
}
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const HomePage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
 List<Friend> friends = [];

 @override
  void initState() {
    super.initState();
    _loadFriends();
  } 
  
  void _loadFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .snapshots()
          .listen((snapshot) {
        final loadedFriends = snapshot.docs.map((doc) {
          return Friend.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        setState(() {
          friends = loadedFriends;
        });
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GiftListPage()),
              );
            },
            child: const Text('My Gifts'),
          ),          
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return ListTile(
            title: Text(friend.name),
            subtitle: Text(friend.phoneNumber),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendGiftListPage(friendId: friend.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFriendPage()),
          ).then((_) => _loadFriends()); // Refresh the list after adding a friend
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}