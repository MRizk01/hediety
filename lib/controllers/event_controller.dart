import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/database_helper.dart';

class EventController {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Load events from local and firestore
    Future<void> loadEvents(String userId, Function(List<Event>) updateUI) async {
      _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .snapshots()
        .listen((QuerySnapshot snapshot) async {
          for (var doc in snapshot.docs) {
            final event = Event.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
            await dbHelper.insertEvent(event, userId);
          }
          final loadedEvents = await dbHelper.getAllEvents(userId);
           updateUI(loadedEvents);
        });
    }

    Future<void> deleteEvent(String eventId, String userId, Function() refreshUI) async {
        // Delete from SQLite
        await dbHelper.deleteEvent(eventId);

        // Delete from Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('events')
            .doc(eventId)
            .delete();

      refreshUI();
    }


  // Save event to local and firestore
    Future<void> saveEvent(Event event, String userId) async {
      await dbHelper.insertEvent(event, userId);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('events')
            .doc(event.id)
            .set(event.toMap());
    }
}