import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediety/controllers/profile_controller.dart';
import 'package:hediety/core/custom_widgets.dart';
import 'package:hediety/views/events/event_list_page.dart';
import 'package:hediety/views/gifts/gift_list_page.dart';
import 'package:hediety/views/gifts/pledged_gifts_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  bool notificationsEnabled = true;
   final ProfileController _profileController = ProfileController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

    void _loadUserProfile() async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
            await _profileController.loadProfile(user.uid, (profileData) {
                 setState(() {
                     nameController.text = profileData['name'] ?? '';
                     emailController.text = profileData['email'] ?? '';
                     phoneController.text = profileData['phone'] ?? '';
                     notificationsEnabled = profileData['notificationsEnabled'] ?? true;
                 });
            });
        }
    }

    void _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
        await _profileController.saveProfile(user.uid, {
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'phone': phoneController.text.trim(),
            'notificationsEnabled': notificationsEnabled,
        });
         if (mounted){
             showNotification('Profile updated successfully!', context);
         }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             CustomTextFormField(
                controller: nameController,
                labelText: 'Name',
              ),
                CustomTextFormField(
                controller: emailController,
                labelText: 'Email',
              ),
             CustomTextFormField(
                 controller: phoneController,
                labelText: 'Phone',
              ),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: notificationsEnabled,
                onChanged: (value) => setState(() => notificationsEnabled = value),
            ),
              CustomElevatedButton(
                onPressed: _saveProfile,
                 child: const Text('Save'),
             ),
              const Divider(),
            const Text('My Events and Gifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               CustomElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                      MaterialPageRoute(builder: (context) => const EventListPage()),
                  );
                },
                   child: const Text('View My Events'),
             ),
                 CustomElevatedButton(
                  onPressed: () {
                                     final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GiftListPage(userId: user.uid)),
                    );
                  }
                },
                 child: const Text('View My Gifts'),
             ),
                CustomElevatedButton(
                  onPressed: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PledgedGiftsPage()),
                      );
                   },
                   child: const Text('My Pledged Gifts'),
             ),
          ],
        ),
      ),
    );
  }
}