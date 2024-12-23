import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediety/controllers/gift_controller.dart';
import 'package:hediety/core/custom_widgets.dart';
import 'package:hediety/models/gift.dart';
import 'package:hediety/utils/connectivity_service.dart';
import 'package:overlay_support/overlay_support.dart';



class GiftDetailsPage extends StatefulWidget {
  final Gift? gift;
  final String? eventId; // New field for the event ID
  const GiftDetailsPage({super.key, this.gift, this.eventId});

  @override
  State<GiftDetailsPage> createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  String _selectedStatus = "available";
  bool _isPledgeButton = false; // New variable for pledge button
  bool _canEdit = true;
    final GiftController _giftController = GiftController();


@override
void initState() {
  super.initState();
  _checkIfCanEdit();
  if (widget.gift != null) {
    nameController.text = widget.gift!.name;
    descriptionController.text = widget.gift!.description;
    categoryController.text = widget.gift!.category;
    priceController.text = widget.gift!.price.toString();
    _selectedStatus = widget.gift!.status;
  }
  


  }

    void _checkIfCanEdit() {
    if (widget.gift != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
            setState(() {
                final isOwner = (user.uid == widget.gift!.userId);
                _canEdit = (isOwner && widget.gift!.status != 'pledged'); // Owner can edit if not pledged
                _isPledgeButton = (!isOwner && widget.gift!.status == 'available'); // Friends can pledge only if available
            });
        }
    } else {
        // If creating a new gift
         _canEdit = true;
         _isPledgeButton = false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _changeStatus(String newStatus) {
      setState(() {
          _selectedStatus = newStatus;
      });

      // Call method to update the gift status in Firestore and show notification
        if (widget.gift != null) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
             _giftController.updateGiftStatus(widget.gift!.id!, user.uid, newStatus);
              showSimpleNotification(
                  const Text('Gift Status Updated'),
                  subtitle: Text('The status has changed to $newStatus'),
                  background: Colors.green,
              );
           }
        }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Details'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Replace TextFormField with CustomTextFormField
               CustomTextFormField(
                controller: nameController,
                labelText: 'Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                readOnly: !_canEdit, // Restrict editing based on the owner and status
              ),
              const SizedBox(height: 10),

              // Description field
               CustomTextFormField(
                controller: descriptionController,
                 labelText: 'Description',
                readOnly: !_canEdit,
              ),
              const SizedBox(height: 10),

              // Category field
                CustomTextFormField(
                controller: categoryController,
                labelText: 'Category',
                readOnly: !_canEdit,
              ),
              const SizedBox(height: 10),

              // Price field
                 CustomTextFormField(
                controller: priceController,
                labelText: 'Price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                 readOnly: !_canEdit,
              ),
              const SizedBox(height: 10),

              // Status dropdown (unchanged)
               DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: ['available', 'pledged', 'purchased'].map((String status) {
                  return DropdownMenuItem<String>(value: status, child: Text(status));
                }).toList(),
                onChanged: _canEdit
                    ? (newValue) {
                        if (newValue != null) {
                          _changeStatus(newValue); // Call the status change method
                        }
                      }
                    : null, // Disable dropdown if editing is not allowed
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 20),

              // Pledge button if applicable
             if (_isPledgeButton)
                CustomElevatedButton(
                  onPressed: () async {
                    if (widget.gift != null) {
                      final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                           await _giftController.pledgeGift(widget.gift!.id!, widget.gift!.userId!, user.uid);
                            setState(() {
                              _selectedStatus = 'pledged';
                              _isPledgeButton = false;
                              _canEdit = false;
                             });

                            // Show notification for successful pledge
                            showSimpleNotification(
                              const Text('Gift Pledged'),
                              subtitle: const Text('You have pledged this gift!'),
                              background: Colors.green,
                            );

                             if (mounted) Navigator.pop(context);
                        }
                    }
                  },
                    child: const Text('Pledge'),
                ),


              // Save button if editable
             if (_canEdit)
                 CustomElevatedButton(
                  onPressed: _saveGift,
                  child: const Text('Save'),
                ),
            ],
          ),
        ),
      ),
    );
  }

    void _saveGift() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
       if (user != null) {
            final newGift = Gift(
                id: widget.gift?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                description: descriptionController.text,
                category: categoryController.text,
                price: double.tryParse(priceController.text) ?? 0.0,
                status: _selectedStatus,
                eventId: widget.eventId,
                userId: user.uid,
            );
           await _giftController.saveGift(newGift, user.uid);

           // Show notification for successful save
          showSimpleNotification(
            const Text('Gift Saved'),
            subtitle: const Text('Your gift has been saved successfully!'),
            background: Colors.green,
           );
             if (mounted) Navigator.pop(context);
        }
    }
  }
}