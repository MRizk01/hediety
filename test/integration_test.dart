import 'package:flutter/material.dart'; // Import material package
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hediety/main.dart' as app; // Import your main app file
  import 'dart:async';


  Future<void> pumpUntilVisible(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 10)}) async {
    bool isVisible = false;
    Stopwatch timer = Stopwatch()..start();
    while (!isVisible) {
      await tester.pump();
      try {
        tester.ensureVisible(finder);
        isVisible = true;
      } catch (e) {
          if (timer.elapsed > timeout) {
            throw TimeoutException("Timeout waiting for element to be visible");
          }
      }
    }
  }

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End User Flow Test', (WidgetTester tester) async {
    app.main(); // Start the app

    await tester.pumpAndSettle(); // Wait for app to start, and settle.

    // Explicitly navigate to the login screen using the GlobalKey
    app.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const app.LoginPage()),
    );

    // Wait for the login page to appear and be built by waiting for email field to be visible
    final emailFieldFinder = find.byKey(const Key('email_field'));
    await pumpUntilVisible(tester, emailFieldFinder);

    debugDumpApp();


    // Find the email and password text fields, and the login button
    final emailField = find.byKey(const Key('email_field'));
    final passwordField = find.byKey(const Key('password_field'));
    final loginButton = find.byKey(const Key('login_button'));

    expect(emailField, findsOneWidget); // Ensure the email field is in the widget tree

    // Tap the email field to ensure it is focused, then enter text
    await tester.tap(emailField);
    await tester.enterText(emailField, 'firstuser@gmail.com');
    await tester.pumpAndSettle();

    // Tap the password field to focus, then enter text
    await tester.tap(passwordField);
    await tester.enterText(passwordField, 'firstuser@gmail.com');
    await tester.pumpAndSettle();

    // Tap the login button
    await tester.tap(loginButton);

    // Wait for some time to give the app time to process the action
    await Future.delayed(const Duration(seconds: 10));

    // Settle the state after the login action completes
    await tester.pumpAndSettle();

    // Additional test steps can go here...
    // Example: You might want to check for successful login or proceed to the next screen
  });
}