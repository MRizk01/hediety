import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hediety/models/gift.dart';
import 'package:hediety/models/database_helper.dart';

class SyncService {

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
}