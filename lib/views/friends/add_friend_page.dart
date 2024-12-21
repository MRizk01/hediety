import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediety/controllers/friend_controller.dart';
import 'package:hediety/core/custom_widgets.dart';


class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController phoneController = TextEditingController();
  final FriendController _friendController = FriendController();

  Future<void> addFriend(BuildContext context, String phoneNumber) async {
    final user = FirebaseAuth.instance.currentUser;
     if (user == null) {
        showNotification('User not logged in.', context);
         return;
     }   

     await _friendController.addFriend(phoneNumber, user.uid, (message) {
           showNotification(message, context);
           Navigator.pop(context);
     });
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
              CustomTextFormField(
              controller: phoneController,
              labelText: 'Friend\'s Phone Number',
            ),
            const SizedBox(height: 16.0),
               CustomElevatedButton(
              onPressed: () => addFriend(context, phoneController.text),
              child: const Text('Add Friend'),
            ),
          ],
        ),
      ),
    );
  }
}