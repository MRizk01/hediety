import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gift.dart';
import '../models/database_helper.dart';

class GiftController {
  final DatabaseHelper dbHelper = DatabaseHelper();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<void> loadGifts(String userId, String? eventId, Function(List<Gift>) updateUI) async {
        _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .snapshots()
        .listen((snapshot) async {
           final firebaseGifts = snapshot.docs
            .map((doc) => Gift.fromFirestore(doc.data(), doc.id))
            .toList();

          for (final gift in firebaseGifts) {
            await dbHelper.insertGift(gift, userId, synced: true);
          }

          final localGifts = await dbHelper.getAllGifts(userId);

          if (eventId != null && eventId.isNotEmpty) {
           updateUI(localGifts.where((element) {
              final isMatchingEvent = element.eventId != null && element.eventId == eventId;
              return isMatchingEvent;
            }).toList());
          } else {
             updateUI(localGifts);
          }
        });
    }

    Future<void> deleteGift(String giftId, String userId, Function(List<Gift>) updateUI) async {
        // Delete from Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('gifts')
            .doc(giftId)
            .delete();

        // Delete from SQLite
       await dbHelper.deleteGift(giftId);

       final localGifts = await dbHelper.getAllGifts(userId);
       updateUI(localGifts);
    }
    
    Future<void> updateGiftStatus(String giftId, String userId, String newStatus) async {
      await _firestore
            .collection('users')
            .doc(userId)
            .collection('gifts')
            .doc(giftId)
            .update({'status': newStatus});
    }

    Future<void> saveGift(Gift gift, String userId) async {
        await dbHelper.insertGift(gift, userId);
         await _firestore
            .collection('users')
            .doc(userId)
            .collection('gifts')
            .doc(gift.id)
            .set(gift.toMap());
    }

  Future<void> pledgeGift(String giftId, String userId, String friendId) async{
         await _firestore
            .collection('users')
            .doc(userId)
            .collection('gifts')
            .doc(giftId)
            .update({
          'status': 'pledged',
          'pledgedBy': friendId,
        });
    }
}