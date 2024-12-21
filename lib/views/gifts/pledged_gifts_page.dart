import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PledgedGiftsPage extends StatefulWidget {
  const PledgedGiftsPage({super.key});

  @override
  State<PledgedGiftsPage> createState() => _PledgedGiftsPageState();
}

class _PledgedGiftsPageState extends State<PledgedGiftsPage> {
  List<Map<String, dynamic>> pledgedGifts = [];

  @override
  void initState() {
    super.initState();
    _loadPledgedGifts();
  }

  void _loadPledgedGifts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final giftsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Query only the current user's gifts
          .collection('gifts')
          .where('status', isEqualTo: 'pledged')
          .get();

      setState(() {
        pledgedGifts = giftsSnapshot.docs.map((doc) {
          return {
            ...doc.data(),
            'id': doc.id,
          };
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pledged Gifts')),
      body: pledgedGifts.isEmpty
          ? const Center(child: Text('No pledged gifts yet.'))
          : ListView.builder(
              itemCount: pledgedGifts.length,
              itemBuilder: (context, index) {
                final gift = pledgedGifts[index];
                return ListTile(
                  title: Text(gift['name']),
                  subtitle: Text('Category: ${gift['category']}'),
                  trailing: Text('\$${gift['price']}'),
                );
              },
            ),
    );
  }
}