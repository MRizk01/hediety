import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hediety/main.dart' as app;
import 'package:hediety/views/auth/login_page.dart';
import 'package:hediety/views/home_page.dart';
import 'dart:async';
import 'package:hediety/utils/constants.dart';

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
    app.main();
    await tester.pumpAndSettle();
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
    final emailFieldFinder = find.byKey(const Key('email_field'));
    await pumpUntilVisible(tester, emailFieldFinder);
    debugDumpApp();
    final emailField = find.byKey(const Key('email_field'));
    final passwordField = find.byKey(const Key('password_field'));
    final loginButton = find.byKey(const Key('login_button'));
    expect(emailField, findsOneWidget);
    await tester.tap(emailField);
    await tester.enterText(emailField, 'firstuser@gmail.com');
    await tester.pumpAndSettle();
    await tester.tap(passwordField);
    await tester.enterText(passwordField, 'password123');
    await tester.pumpAndSettle();
    await tester.tap(loginButton);
    await Future.delayed(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('Create Event and Add Gift Flow Test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
      navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
    final createEventButton = find.byKey(const Key('create_event_button'));
    await tester.tap(createEventButton);
    await tester.pumpAndSettle();
    final eventNameField = find.byKey(const Key('event_name_field'));
    final saveEventButton = find.byKey(const Key('save_event_button'));
    await tester.tap(eventNameField);
    await tester.enterText(eventNameField, 'Birthday Party');
    await tester.tap(saveEventButton);
    await tester.pumpAndSettle();
    final addGiftButton = find.byKey(const Key('add_gift_button'));
    await tester.tap(addGiftButton);
    await tester.pumpAndSettle();
    final giftNameField = find.byKey(const Key('gift_name_field'));
    final saveGiftButton = find.byKey(const Key('save_gift_button'));
    await tester.tap(giftNameField);
    await tester.enterText(giftNameField, 'Toy Car');
    await tester.tap(saveGiftButton);
    await tester.pumpAndSettle();
  });

  testWidgets('Add Friend and Pledge Gift Flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
       navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
    final addFriendButton = find.byKey(const Key('add_friend_button'));
    await tester.tap(addFriendButton);
    await tester.pumpAndSettle();
    final friendNameField = find.byKey(const Key('friend_name_field'));
    final saveFriendButton = find.byKey(const Key('save_friend_button'));
    await tester.tap(friendNameField);
    await tester.enterText(friendNameField, 'John Doe');
    await tester.tap(saveFriendButton);
    await tester.pumpAndSettle();
    final pledgeGiftButton = find.byKey(const Key('pledge_gift_button'));
    await tester.tap(pledgeGiftButton);
    await tester.pumpAndSettle();
    final pledgeGiftNameField = find.byKey(const Key('pledge_gift_name_field'));
    final confirmPledgeButton = find.byKey(const Key('confirm_pledge_button'));
    await tester.tap(pledgeGiftNameField);
    await tester.enterText(pledgeGiftNameField, 'Board Game');
    await tester.tap(confirmPledgeButton);
    await tester.pumpAndSettle();
  });
}