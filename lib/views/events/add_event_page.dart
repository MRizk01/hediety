import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediety/controllers/event_controller.dart';
import 'package:hediety/core/custom_widgets.dart';
import 'package:hediety/models/event.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final EventController _eventController = EventController();


  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

    void _saveEvent() async {
        if (_formKey.currentState!.validate()) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
                final newEvent = Event(
                    id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
                    name: nameController.text,
                    date: dateController.text,
                    location: locationController.text,
                    description: descriptionController.text,
                );

              await _eventController.saveEvent(newEvent, user.uid);

               if (mounted) {
                  Navigator.pop(context);
               }
            }
        }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Event Name field
                CustomTextFormField(
                controller: nameController,
                labelText: 'Event Name',
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 10), // Add space between fields

              // Date field
                CustomTextFormField(
                controller: dateController,
                labelText: 'Date',
              ),
              const SizedBox(height: 10), // Add space between fields

              // Location field
               CustomTextFormField(
                controller: locationController,
                 labelText: 'Location',
              ),
              const SizedBox(height: 10),

              // Description field
              CustomTextFormField(
                controller: descriptionController,
                labelText: 'Description',
              ),
              const SizedBox(height: 20), // Add space before the button
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveEvent,
        child: const Icon(Icons.save), // Add save icon to the button
      ),
    );
  }
}