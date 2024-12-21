import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<void> loadProfile(String userId, Function(Map<String, dynamic>) updateUI) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
        updateUI(userDoc.data() as Map<String,dynamic>);
    }
  }

  Future<void> saveProfile(String userId, Map<String, dynamic> profileData) async {
      await _firestore.collection('users').doc(userId).update(profileData);
  }
}