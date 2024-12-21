import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediety/controllers/gift_controller.dart';
import 'package:hediety/models/gift.dart';
import 'package:hediety/views/gifts/gift_details_page.dart';

class GiftListPage extends StatefulWidget {
  final String? eventId;
  final String userId;

  const GiftListPage({super.key, this.eventId, required this.userId});

  @override
  State<GiftListPage> createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  List<Gift> gifts = [];
  final GiftController _giftController = GiftController();
    
  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

   void _loadGifts() async {
     _giftController.loadGifts(widget.userId, widget.eventId, (loadedGifts){
        setState(() {
          gifts = loadedGifts;
        });
     });
  }

  // Adding the getStatusColor method to color code the gift status
  Color getStatusColor(String status) {
    switch (status) {
      case 'pledged':
        return Colors.green;
      case 'purchased':
        return Colors.red;
      case 'available':
      default:
        return Colors.blue;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
      ),
      body: ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return Card(
            color: getStatusColor(gift.status), // Apply the color based on the gift's status
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Margin for spacing
            elevation: 4, // Elevation for shadow
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Rounded corners
            child: ListTile(
              title: Text(gift.name),
               onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GiftDetailsPage(
                      gift: gift,
                      eventId: gift.eventId,
                    ),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (FirebaseAuth.instance.currentUser!.uid == widget.userId && gift.status != "pledged")
                     IconButton(
                        icon: const Icon(Icons.delete),
                         onPressed: () => _deleteGift(gift.id!),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
           if (FirebaseAuth.instance.currentUser!.uid == widget.userId)
             FloatingActionButton(
               onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => GiftDetailsPage(eventId: widget.eventId),
                    ),
                );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
  
    void _deleteGift(String giftId) async {
        final user = FirebaseAuth.instance.currentUser;
      final gift = gifts.firstWhere((g) => g.id == giftId);
        if (gift.status == 'pledged') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot delete a pledged gift.')),
            );
             return;
       }
     if (user != null) {
       await _giftController.deleteGift(giftId, widget.userId, (loadedGifts){
          setState(() {
            gifts = loadedGifts;
          });
       });
      }
    }
}