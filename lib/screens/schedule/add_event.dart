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
  final _formKey = GlobalKey<FormState>(); // form validation
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  EventType _selectedType = EventType.other;
  int _notificationMinutes = 30;
  bool _shareToCommunity = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: AppColors.accent, width: 2),
      ),
      title: Center(
        child: Text(
          'Add New Event',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event title input
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),

              // Event description input
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Event type dropdown
              DropdownButtonFormField<EventType>(
                value: _selectedType,
                dropdownColor: AppColors.primary,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Event Type',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
                items: EventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 12),

              // Date & time picker
              ListTile(
                tileColor: AppColors.background.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.accent),
                ),
                title: Text(
                  'Date: ${DateFormat('MMM d, yyyy').format(widget.selectedDate)}',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  'Time: ${DateFormat('hh:mm a').format(_selectedTime)}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: Icon(Icons.edit, color: AppColors.accent),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 12),

              // Reminder time dropdown
              Consumer<EventProvider>(
                builder: (context, eventProvider, child) {
                  return DropdownButtonFormField<int>(
                    value: _notificationMinutes,
                    dropdownColor: AppColors.primary,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Reminder Time',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                    items: EventProvider.notificationTimeOptions.map((minutes) {
                      return DropdownMenuItem(
                        value: minutes,
                        child: Text(
                          EventProvider.getNotificationTimeText(minutes),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _notificationMinutes = value!),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Share to community switch
              SwitchListTile(
                title: Text(
                  'Share to Community',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  'Other pet owners can join your activity',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                activeColor: AppColors.accent,
                value: _shareToCommunity,
                onChanged: (value) =>
                    setState(() => _shareToCommunity = value),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        // Cancel button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.accent),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.accent)),
        ),

        // Save button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _saveEvent(context),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // Time picker for event
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

  // Save event to Firestore via provider
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
        sharedToCommunity: _shareToCommunity,
      );

      // Add event through provider
      Provider.of<EventProvider>(
        context,
        listen: false,
      ).addEvent(event, shareToCommunity: _shareToCommunity);

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
