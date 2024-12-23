import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend.dart';
import '../models/database_helper.dart';


class FriendController {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
     final DatabaseHelper dbHelper = DatabaseHelper();

    Future<void> addFriend(String phoneNumber,String userId, Function(String) showMessage) async {
        try {
             QuerySnapshot query = await _firestore
                .collection('users')
                .where('phone', isEqualTo: phoneNumber.trim())
                .get();

            if (query.docs.isNotEmpty) {
                final friendData = query.docs.first;
                final friendUid = friendData.id; // The friend's UID
                final friendName = friendData['name'] ?? 'Unknown';
                final friendEmail = friendData['email'] ?? 'Unknown';
                final friendPhone = friendData['phone'] ?? 'Unknown';        

                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('friends')
                    .doc(friendUid)
                    .set({
                    'name': friendName,
                    'email': friendEmail,
                    'phone': friendPhone,
                });
                  showMessage('$friendName has been added as a friend.');


            } else {
               showMessage('User with this phone number does not exist.');
            }
        } catch (e) {
             showMessage('An error occurred while adding the friend.');
        }
    }
        Future<void> loadFriends(String userId, Function(List<Friend>) updateUI) async {
        _firestore
            .collection('users')
            .doc(userId)
            .collection('friends')
            .snapshots()
            .listen((friendsSnapshot) async {
             final loadedFriends = friendsSnapshot.docs
              .map((doc) => Friend.fromFirestore(doc.data(), doc.id))
              .toList();
                updateUI(loadedFriends);
        });
    }

    Future<int> getUpcomingEventCount(String friendId) async {
        final user = _auth.currentUser;
        if (user == null) return 0;
            final snapshot = await _firestore
                .collection('users')
                .doc(friendId)
                .collection('events')
                .get();
             return snapshot.docs.length;
    }
}