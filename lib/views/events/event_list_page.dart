import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediety/controllers/event_controller.dart';
import 'package:hediety/models/event.dart';
import 'package:hediety/views/events/add_event_page.dart';
import 'package:hediety/views/gifts/gift_list_page.dart';


class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Event> events = [];
  final EventController _eventController = EventController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
      final user = FirebaseAuth.instance.currentUser;
      if(user != null){
        _eventController.loadEvents(user.uid, (loadedEvents) {
          setState(() {
            events = loadedEvents;
          });
        });
      }
  }

    void _deleteEvent(String eventId) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
         await _eventController.deleteEvent(eventId, user.uid, _loadEvents);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
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
                  builder: (context) => GiftListPage(eventId: event.id!, userId: FirebaseAuth.instance.currentUser!.uid),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteEvent(event.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventPage()),
          ).then((_) => _loadEvents());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}