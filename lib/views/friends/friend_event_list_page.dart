import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediety/models/event.dart';
import 'package:hediety/models/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hediety/views/gifts/gift_list_page.dart';

class FriendEventListPage extends StatefulWidget {
  final String friendId;
  const FriendEventListPage({super.key, required this.friendId});

  @override
  State<FriendEventListPage> createState() => _FriendEventListPageState();
}

class _FriendEventListPageState extends State<FriendEventListPage> {
  List<Event> events = [];
   final DatabaseHelper dbHelper = DatabaseHelper();


  @override
    void initState() {
       super.initState();
       _loadEvents();
    }


    void _loadEvents() async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return; //Handle user not logged in case
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.friendId)
            .collection('events')
            .snapshots()
            .listen((snapshot) async {
            final dbHelper = DatabaseHelper();
            for (var doc in snapshot.docs) {
                final event = Event.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                await dbHelper.insertEvent(event, widget.friendId);
            }

            final loadedEvents = await dbHelper.getAllEvents(widget.friendId);
            setState(() {
                 events = loadedEvents;
            });
         });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend\'s Events')),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            title: Text(event.name),
            subtitle: Text(event.date),
             onTap: () {
                Navigator.push(
                    context,
                   MaterialPageRoute(
                        builder: (context) => GiftListPage(eventId: event.id!, userId: widget.friendId),
                   ),
                );
            },
          );
        },
      ),
   );
  }
}