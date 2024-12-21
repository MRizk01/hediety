import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
       throw e;
    }
  }

    Future<UserCredential> register(String email, String password) async {
       try {
           return await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

      } on FirebaseAuthException catch (e) {
        throw e;
      }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }


  Stream<User?> authStateChanges() {
        return _auth.authStateChanges();
      }
}