import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediety/controllers/friend_controller.dart';
import 'package:hediety/models/friend.dart';
import 'package:hediety/views/events/add_event_page.dart';
import 'package:hediety/views/events/event_list_page.dart';
import 'package:hediety/views/gifts/gift_list_page.dart';
import 'package:hediety/views/friends/add_friend_page.dart';
import 'package:hediety/views/friends/friend_event_list_page.dart';
import 'package:hediety/views/profile_page.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Friend> friends = [];
  final FriendController _friendController = FriendController();


  @override
  void initState() {
    super.initState();
    _loadFriendsWithEventCounts();
  }


  Future<void> _loadFriendsWithEventCounts() async {
      final user = FirebaseAuth.instance.currentUser;
       if (user == null) return; // Handle user not logged in case
        _friendController.loadFriends(user.uid, (loadedFriends) async {
            // Fetch events for each friend
            List<FriendWithEvents> friendsWithEvents = [];
           for (var friend in loadedFriends) {
               final eventCount = await _friendController.getUpcomingEventCount(friend.id!);
               friendsWithEvents.add(
                   FriendWithEvents(friend: friend, upcomingEventCount: eventCount));
            }

          // Check if the widget is still mounted before calling setState
            if (mounted) {
                setState(() {
                 friends = friendsWithEvents.map((e) => e.friend).toList();
               });
          }
     });
  }

  @override
    void dispose() {
       super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
         actions: [
          IconButton(
            icon: const Icon(Icons.person),
             onPressed: () {
                 Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                 );
             },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Icon-based Buttons for "My Gifts" and "My Events"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.card_giftcard),
                label: const Text('My Gifts'),
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GiftListPage(userId: user.uid),
                      ),
                    );
                  }
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.event),
                label: const Text('My Events'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventListPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Add some spacing between buttons and friends list
          // List of friends
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: ListTile(
                    title: Text(friend.name),
                      onTap: () {
                      Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FriendEventListPage(friendId: friend.id!),
                            ),
                      );
                   },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
           FloatingActionButton(
            heroTag: "addEventButton",
            onPressed: () {
                Navigator.push(
                   context,
                    MaterialPageRoute(builder: (context) => const AddEventPage()),
                );
            },
              child: const Icon(Icons.add),
            ),
           const SizedBox(width: 10),
            FloatingActionButton(
             heroTag: "addFriendButton",
             onPressed: () {
              Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddFriendPage()),
              ).then((_) => _loadFriendsWithEventCounts()); // Refresh the list after adding a friend
            },
              child: const Icon(Icons.person_add),
           ),
        ],
      ),
    );
  }
}

class FriendWithEvents {
    final Friend friend;
   final int upcomingEventCount;
  FriendWithEvents({required this.friend, required this.upcomingEventCount});
}