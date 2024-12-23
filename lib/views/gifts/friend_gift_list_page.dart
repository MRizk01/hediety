import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FriendGiftListPage extends StatelessWidget {
  final String friendId;
  const FriendGiftListPage({super.key, required this.friendId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend\'s Gift List')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .collection('gifts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No gifts available.'));
          }

          final gifts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];
              return ListTile(
                title: Text(gift['name']),
                subtitle: Text(gift['description']),
              );
            },
          );
        },
      ),
    );
  }
}