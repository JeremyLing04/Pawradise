import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../constants.dart';

class EditEventDialog extends StatefulWidget {
  final Event event;

  const EditEventDialog({super.key, required this.event});

  @override
  State<EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<EditEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedTime;
  late EventType _selectedType;
  late int _notificationMinutes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(
      text: widget.event.description ?? '',
    );
    _selectedTime = widget.event.scheduledTime;
    _selectedType = widget.event.type;
    _notificationMinutes = widget.event.notificationMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
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
              ListTile(
                title: Text(
                  'Date: ${DateFormat('MMM d, yyyy').format(_selectedTime)}',
                ),
                subtitle: Text(
                  'Time: ${DateFormat('hh:mm a').format(_selectedTime)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _notificationMinutes,
                items: EventProvider.notificationTimeOptions.map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text(EventProvider.getNotificationTimeText(minutes)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _notificationMinutes = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Reminder Time'),
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
          onPressed: () => _updateEvent(context),
          child: const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _updateEvent(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final updatedEvent = Event(
        id: widget.event.id,
        userId: userId, // 保证使用当前用户 UID
        petId: widget.event.petId,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        type: _selectedType,
        scheduledTime: _selectedTime,
        isCompleted: widget.event.isCompleted,
        createdAt: widget.event.createdAt,
        notificationMinutes: _notificationMinutes,
      );

      Provider.of<EventProvider>(
        context,
        listen: false,
      ).updateEvent(updatedEvent);

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
