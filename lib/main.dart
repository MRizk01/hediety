import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_db;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:overlay_support/overlay_support.dart';
import 'theme.dart';
import 'custom_widgets.dart';



class PledgedGiftsPage extends StatefulWidget {
  const PledgedGiftsPage({super.key});

  @override
  State<PledgedGiftsPage> createState() => _PledgedGiftsPageState();
}

class _PledgedGiftsPageState extends State<PledgedGiftsPage> {
  List<Map<String, dynamic>> pledgedGifts = [];

  @override
  void initState() {
    super.initState();
    _loadPledgedGifts();
  }

  void _loadPledgedGifts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final giftsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Query only the current user's gifts
          .collection('gifts')
          .where('status', isEqualTo: 'pledged')
          .get();

      setState(() {
        pledgedGifts = giftsSnapshot.docs.map((doc) {
          return {
            ...doc.data(),
            'id': doc.id,
          };
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pledged Gifts')),
      body: pledgedGifts.isEmpty
          ? const Center(child: Text('No pledged gifts yet.'))
          : ListView.builder(
              itemCount: pledgedGifts.length,
              itemBuilder: (context, index) {
                final gift = pledgedGifts[index];
                return ListTile(
                  title: Text(gift['name']),
                  subtitle: Text('Category: ${gift['category']}'),
                  trailing: Text('\$${gift['price']}'),
                );
              },
            ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          nameController.text = userDoc['name'] ?? '';
          emailController.text = userDoc['email'] ?? '';
          phoneController.text = userDoc['phone'] ?? '';
          notificationsEnabled = userDoc['notificationsEnabled'] ?? true;
        });
      }
    }
  }

  void _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'notificationsEnabled': notificationsEnabled,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: notificationsEnabled,
              onChanged: (value) => setState(() => notificationsEnabled = value),
            ),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
            const Divider(),
            const Text('My Events and Gifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventListPage()),
                );
              },
              child: const Text('View My Events'),
            ),
            ElevatedButton(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GiftListPage(userId: user.uid)),
                  );
                }
              },
              child: const Text('View My Gifts'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PledgedGiftsPage()),
                );
              },
              child: const Text('My Pledged Gifts'),
            ),
          ],
        ),
      ),
    );
  }
}


Future<void> syncLocalToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final dbHelper = DatabaseHelper();
    
    // Fetch all unsynced gifts from the local SQLite database
    final unsyncedGifts = await dbHelper.getAllGifts(user.uid);
    
    // Iterate through each unsynced gift
    for (var gift in unsyncedGifts) {
      if (gift.id == null || gift.id!.isEmpty) {
        // If the gift doesn't have an ID, it means it's not yet in Firestore, so we need to add it.
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('gifts')
            .add({
              ...gift.toMap(),  // Ensure the existing fields from gift are included
              'status': gift.status,  // Explicitly include the status field
            });

        // After adding, update the gift ID from Firestore and mark it as synced in the local database
        gift.id = docRef.id;
        await dbHelper.insertGift(gift, user.uid, synced: true);
      } else {
        // If the gift already has an ID, update the existing document in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('gifts')
            .doc(gift.id)
            .set({
              ...gift.toMap(),  // Ensure the existing fields from gift are included
              'status': gift.status,  // Explicitly sync the status field
            }, SetOptions(merge: true));  // Merge to avoid overwriting other fields
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
      name: map['name'] ?? 'Unknown', 
      phoneNumber: map['phoneNumber'] ?? 'Unknown', 
    );
  }


  static Friend fromFirestore(Map<String, dynamic> map, String id) {
    return Friend(
      id: id,
      name: map['name'] ?? 'Unknown', 
      phoneNumber: map['phoneNumber'] ?? 'Unknown', 
    );
  }

}

class Event {
  String? id;
  String name;
  String date;
  String location;
  String description;

  Event({
    this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'location': location,
      'description': description,
    };
  }

  static Event fromSQLite(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      location: map['location'],
      description: map['description'],
    );
  }

  static Event fromFirestore(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      name: map['name'],
      date: map['date'],
      location: map['location'],
      description: map['description'],
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
  String? eventId; // New field to associate the gift with an event
  String? userId; // New field to associate the gift with a user

  Gift({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
    this.eventId,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'eventId': eventId,
      'userId': userId,
    };
  }

  factory Gift.fromFirestore(Map<String, dynamic> data, String id) {
    return Gift(
      id: id,
      name: data['name'] ?? 'Unknown',
      description: data['description'] ?? 'Unknown',
      category: data['category'] ?? 'Unknown',
      price: data['price']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'available',
      eventId: data['eventId'],
      userId: data['userId'],
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
      eventId: map['event_id'],
      userId: map['user_id'],
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

  Future<void> addFriend(BuildContext context, String phoneNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }    

    try {
      // Search for the user with the entered phone number
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneNumber.trim())
          .get();

      if (query.docs.isNotEmpty) {
        final friendData = query.docs.first;
        final friendUid = friendData.id; // The friend's UID
        final friendName = friendData['name'] ?? 'Unknown';
        final friendEmail = friendData['email'] ?? 'Unknown';
        final friendPhone = friendData['phone'] ?? 'Unknown';        


        // Add the friend to the current user's friends list
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('friends')
            .doc(friendUid)
            .set({
          'name': friendName,
          'email': friendEmail,
          'phone': friendPhone,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$friendName has been added as a friend.')),
          );
          Navigator.pop(context);
        }

      } else {
        // No user found with this phone number
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User with this phone number does not exist.')),
        );
      }
    } catch (e) {
      print('Failed to add friend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while adding the friend.')),
      );
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
              decoration: const InputDecoration(labelText: 'Friend\'s Phone Number'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => addFriend(context, phoneController.text),
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
  Future<void> registerUser(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            'email': emailController.text.trim(),
          });
          if (mounted){
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User registered successfully!')),
            );
          }
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
        print('Unexpected error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed:() => registerUser(context),
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Event> events = [];
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .snapshots()
          .listen((QuerySnapshot snapshot) async {
        final dbHelper = DatabaseHelper();
        for (var doc in snapshot.docs) {
          final event = Event.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          await dbHelper.insertEvent(event, user.uid);
        }
        final loadedEvents = await dbHelper.getAllEvents(user.uid);
        setState(() {
          events = loadedEvents;
        });
      });
    }
  }


  void _deleteEvent(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Delete from SQLite
      await dbHelper.deleteEvent(eventId);

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .doc(eventId)
          .delete();

      _loadEvents(); // Refresh event list
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            title: Text(event.name),
            subtitle: Text(event.date),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiftListPage(eventId: event.id!, userId: FirebaseAuth.instance.currentUser!.uid),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteEvent(event.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventPage()),
          ).then((_) => _loadEvents());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newEvent = Event(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
          name: nameController.text,
          date: dateController.text,
          location: locationController.text,
          description: descriptionController.text,
        );

        final dbHelper = DatabaseHelper();
        await dbHelper.insertEvent(newEvent, user.uid);

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('events')
            .doc(newEvent.id)
            .set(newEvent.toMap());

        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Event Name field
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 10), // Add space between fields

              // Date field
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
              const SizedBox(height: 10), // Add space between fields

              // Location field
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 10),

              // Description field
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 20), // Add space before the button
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveEvent,
        child: const Icon(Icons.save), // Add save icon to the button
      ),
    );
  }
}




// UI Code (GiftListPage and GiftDetailsPage)
class GiftListPage extends StatefulWidget {
  final String? eventId;
  final String userId;

  const GiftListPage({super.key, this.eventId, required this.userId});

  @override
  State<GiftListPage> createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  List<Gift> gifts = [];
  late StreamSubscription<QuerySnapshot> _giftsSubscription;
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadGifts();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncLocalToFirestore(); // Trigger sync when back online
      }
    });
  }

  void _loadGifts() async {
    final dbHelper = DatabaseHelper();
    logger.i('GiftListPage: Listening for gifts for user: ${widget.userId}');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _giftsSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('gifts')
          .snapshots()
          .listen((snapshot) async {
        logger.i('GiftListPage: Firestore data changed. ${snapshot.docs.length} docs.');
        final firebaseGifts = snapshot.docs
            .map((doc) => Gift.fromFirestore(doc.data(), doc.id))
            .toList();

        logger.i("GiftListPage: FirebaseGifts: ${firebaseGifts.map((e) => e.toMap())}");

        for (final gift in firebaseGifts) {
          await dbHelper.insertGift(gift, widget.userId, synced: true);
        }

        final localGifts = await dbHelper.getAllGifts(widget.userId);

        if (widget.eventId != null && widget.eventId!.isNotEmpty) {
          logger.i('GiftListPage: Filtering by eventId: ${widget.eventId}');
          setState(() {
            gifts = localGifts.where((element) {
              final isMatchingEvent = element.eventId != null && element.eventId == widget.eventId;
              logger.i('GiftListPage: Checking gift ${element.name} eventId: ${element.eventId}, match: $isMatchingEvent');
              return isMatchingEvent;
            }).toList();

            logger.i("GiftListPage: gifts after filter: ${gifts.map((e) => e.toMap())}");
          });
        } else {
          setState(() {
            gifts = localGifts;
            logger.i("GiftListPage: All local gifts ${gifts.map((e) => e.toMap())}");
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _giftsSubscription.cancel();
    super.dispose();
  }

  // Adding the getStatusColor method to color code the gift status
  Color getStatusColor(String status) {
    switch (status) {
      case 'pledged':
        return Colors.green;
      case 'purchased':
        return Colors.red;
      case 'available':
      default:
        return Colors.blue;
    }
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
          return Card(
            color: getStatusColor(gift.status), // Apply the color based on the gift's status
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Margin for spacing
            elevation: 4, // Elevation for shadow
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Rounded corners
            child: ListTile(
              title: Text(gift.name),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GiftDetailsPage(
                      gift: gift,
                      eventId: gift.eventId,
                    ),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (FirebaseAuth.instance.currentUser!.uid == widget.userId && gift.status != "pledged")
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteGift(gift.id!),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (FirebaseAuth.instance.currentUser!.uid == widget.userId)
            FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GiftDetailsPage(eventId: widget.eventId),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }

  void _deleteGift(String giftId) async {
    final user = FirebaseAuth.instance.currentUser;
    final gift = gifts.firstWhere((g) => g.id == giftId);
    if (gift.status == 'pledged') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete a pledged gift.')),
      );
      return;
    }
    if (user != null) {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('gifts')
          .doc(giftId)
          .delete();

      // Delete from SQLite
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteGift(giftId);

      if (mounted) {
        setState(() {
          gifts.removeWhere((gift) => gift.id == giftId);
        });
      }
    }
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
          print('FriendGiftListPage: Gifts count: ${gifts.length} for user id: $friendId');
           for(final doc in gifts) {
              print("FriendGiftListPage: Gift data ${doc.data()} and doc Id is: ${doc.id}");// Log all firestore data retrieved
          }          
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
  final String? eventId; // New field for the event ID
  const GiftDetailsPage({super.key, this.gift, this.eventId});

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
  bool _isPledgeButton = false; // New variable for pledge button
  bool _canEdit = true;

  @override
  void initState() {
    super.initState();
    _checkIfCanEdit();
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

  void _checkIfCanEdit() {
    if (widget.gift != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          final isOwner = (user.uid == widget.gift!.userId);
          _canEdit = (isOwner && widget.gift!.status != 'pledged'); // Owner can edit if not pledged
          _isPledgeButton = (!isOwner && widget.gift!.status == 'available'); // Friends can pledge only if available
        });
      }
    } else {
      // If creating a new gift
      _canEdit = true;
      _isPledgeButton = false;
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

  void _changeStatus(String newStatus) {
    setState(() {
      _selectedStatus = newStatus;
    });

    // Call method to update the gift status in Firestore and show notification
    _updateGiftStatus(widget.gift!.id!, newStatus);
  }

  void _updateGiftStatus(String giftId, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('gifts')
          .doc(giftId)
          .update({'status': newStatus});

      // Show notification for status change
      showSimpleNotification(
        Text('Gift Status Updated'),
        subtitle: Text('The status has changed to $newStatus'),
        background: Colors.green,
      );
    }
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
              // Replace TextFormField with CustomTextFormField
              CustomTextFormField(
                controller: nameController,
                labelText: 'Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                readOnly: !_canEdit, // Restrict editing based on the owner and status
              ),
              const SizedBox(height: 10),

              // Description field
              CustomTextFormField(
                controller: descriptionController,
                labelText: 'Description',
                readOnly: !_canEdit,
              ),
              const SizedBox(height: 10),

              // Category field
              CustomTextFormField(
                controller: categoryController,
                labelText: 'Category',
                readOnly: !_canEdit,
              ),
              const SizedBox(height: 10),

              // Price field
              CustomTextFormField(
                controller: priceController,
                labelText: 'Price',
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
                readOnly: !_canEdit,
              ),
              const SizedBox(height: 10),

              // Status dropdown (unchanged)
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: ['available', 'pledged', 'purchased'].map((String status) {
                  return DropdownMenuItem<String>(value: status, child: Text(status));
                }).toList(),
                onChanged: _canEdit
                    ? (newValue) {
                        if (newValue != null) {
                          _changeStatus(newValue); // Call the status change method
                        }
                      }
                    : null, // Disable dropdown if editing is not allowed
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 20),

              // Pledge button if applicable
              if (_isPledgeButton)
                CustomElevatedButton(
                  onPressed: () async {
                    if (widget.gift != null) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.gift!.userId)
                            .collection('gifts')
                            .doc(widget.gift!.id)
                            .update({
                          'status': 'pledged',
                          'pledgedBy': user.uid,
                        });

                        setState(() {
                          _selectedStatus = 'pledged';
                          _isPledgeButton = false;
                          _canEdit = false;
                        });

                        // Show notification for successful pledge
                        showSimpleNotification(
                          Text('Gift Pledged'),
                          subtitle: Text('You have pledged this gift!'),
                          background: Colors.green,
                        );

                        if (mounted) Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Pledge'),
                ),

              // Save button if editable
              if (_canEdit)
                CustomElevatedButton(
                  onPressed: _saveGift,
                  child: const Text('Save'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGift() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newGift = Gift(
          id: widget.gift?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameController.text,
          description: descriptionController.text,
          category: categoryController.text,
          price: double.tryParse(priceController.text) ?? 0.0,
          status: _selectedStatus,
          eventId: widget.eventId,
          userId: user.uid,
        );

        final dbHelper = DatabaseHelper();
        await dbHelper.insertGift(newGift, user.uid);

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('gifts')
            .doc(newGift.id)
            .set(newGift.toMap());

        // Show notification for successful save
        showSimpleNotification(
          Text('Gift Saved'),
          subtitle: Text('Your gift has been saved successfully!'),
          background: Colors.green,
        );

        if (mounted) Navigator.pop(context);
      }
    }
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
    return OverlaySupport.global(  // Wrap your MaterialApp with OverlaySupport.global
      child: MaterialApp(
        title: 'Hedieaty',
        theme: AppTheme.getTheme(),
        home: const AuthGate(),  // Replace with your desired home widget
      ),
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
          return const LoginPage();
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
    _loadFriendsWithEventCounts();
  }

  Future<void> _loadFriendsWithEventCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Handle user not logged in case
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .snapshots()
        .listen((friendsSnapshot) async {
      final loadedFriends = friendsSnapshot.docs
          .map((doc) => Friend.fromFirestore(doc.data(), doc.id))
          .toList();

      // Fetch events for each friend
      List<FriendWithEvents> friendsWithEvents = [];
      for (var friend in loadedFriends) {
        final eventCount = await _getUpcomingEventCount(friend.id!);
        friendsWithEvents.add(
            FriendWithEvents(friend: friend, upcomingEventCount: eventCount));
      }
      setState(() {
        friends = friendsWithEvents.map((e) => e.friend).toList();
      });
    });
  }

  Future<int> _getUpcomingEventCount(String friendId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .collection('events')
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Icon-based Buttons for "My Gifts" and "My Events"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.card_giftcard),
                label: const Text('My Gifts'),
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GiftListPage(userId: user.uid),
                      ),
                    );
                  }
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.event),
                label: const Text('My Events'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventListPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Add some spacing between buttons and friends list
          // List of friends
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: ListTile(
                    title: Text(friend.name),
                    subtitle: Text('${friend.phoneNumber}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendEventListPage(friendId: friend.id!),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "addEventButton",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "addFriendButton",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFriendPage()),
              ).then((_) => _loadFriendsWithEventCounts()); // Refresh the list after adding a friend
            },
            child: const Icon(Icons.person_add),
          ),
        ],
      ),
    );
  }
}



class FriendEventListPage extends StatefulWidget {
  final String friendId;
  const FriendEventListPage({super.key, required this.friendId});

  @override
  State<FriendEventListPage> createState() => _FriendEventListPageState();
}

class _FriendEventListPageState extends State<FriendEventListPage> {
  List<Event> events = [];
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
    void initState() {
       super.initState();
       _loadEvents();
    }

  void _loadEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; //Handle user not logged in case
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.friendId)
        .collection('events')
        .snapshots()
        .listen((snapshot) async {
      final dbHelper = DatabaseHelper();
      for (var doc in snapshot.docs) {
        final event = Event.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        await dbHelper.insertEvent(event, widget.friendId);
      }

      final loadedEvents = await dbHelper.getAllEvents(widget.friendId);
      setState(() {
        events = loadedEvents;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend\'s Events')),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            title: Text(event.name),
            subtitle: Text(event.date),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiftListPage(eventId: event.id!, userId: widget.friendId),
                ),
              );
            },
          );
        },
      ),
   );
  }
}

class FriendWithEvents {
  final Friend friend;
  final int upcomingEventCount;
  FriendWithEvents({required this.friend, required this.upcomingEventCount});
}