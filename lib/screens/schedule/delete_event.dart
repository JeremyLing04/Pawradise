import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../constants.dart';

class DeleteEventDialog extends StatelessWidget {
  final Event event;

  const DeleteEventDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Dialog background color
      backgroundColor: AppColors.secondary,
      // Rounded border with accent color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.accent, width: 2),
      ),
      title: Center(
        child: Text(
          'Delete Event',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Text(
        'Are you sure you want to delete this event?',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        // Delete button (red to indicate danger)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 221, 133, 127),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            // Get current user ID
            final userId = FirebaseAuth.instance.currentUser!.uid;
            // Call provider to delete event
            Provider.of<EventProvider>(
              context,
              listen: false,
            ).deleteEvent(event.id, userId);
            // Close dialog
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
