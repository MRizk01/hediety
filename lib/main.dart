import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/app.dart';
import 'package:hediety/views/auth/auth_gate.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';

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
  runApp(const HedieatyApp(home: AuthGate()));
}