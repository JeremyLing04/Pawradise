import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../constants.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;

  const AddEventDialog({super.key, required this.selectedDate});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>(); //validate input
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  EventType _selectedType = EventType.other;
  int _notificationMinutes = 30;

  //initialize
  @override
  void initState() {
    super.initState();
    _selectedTime = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              //description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),

              //event type
              DropdownButtonFormField<EventType>(
                value: _selectedType,
                items: EventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Event Type'),
              ),

              //date & time choose
              ListTile(
                title: Text(
                  'Date: ${DateFormat('MMM d, yyyy').format(widget.selectedDate)}',
                ),
                subtitle: Text(
                  'Time: ${DateFormat('hh:mm a').format(_selectedTime)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 16),

              //notification min
              Consumer<EventProvider>(
                builder: (context, eventProvider, child) {
                  return DropdownButtonFormField<int>(
                    value: _notificationMinutes,
                    items: EventProvider.notificationTimeOptions.map((minutes) {
                      return DropdownMenuItem(
                        value: minutes,
                        child: Text(
                          EventProvider.getNotificationTimeText(minutes),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _notificationMinutes = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Reminder Time',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _saveEvent(context),
          child: const Text('Save'),
        ),
      ],
    );
  }

  //event time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  // save event
  void _saveEvent(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final event = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        petId: 'default_pet_id',
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        type: _selectedType,
        scheduledTime: _selectedTime,
        isCompleted: false,
        createdAt: DateTime.now(),
        notificationMinutes: _notificationMinutes,
      );

      // add event 到 Firestore
      Provider.of<EventProvider>(context, listen: false).addEvent(event);

      // close dialog
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
