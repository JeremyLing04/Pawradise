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
      backgroundColor: AppColors.secondary, // 背景主题色
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.accent, width: 2), // 边框
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
        // cancel 按钮
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        // delete 按钮（红色更突出危险操作）
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 221, 133, 127),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final userId = FirebaseAuth.instance.currentUser!.uid;
            Provider.of<EventProvider>(
              context,
              listen: false,
            ).deleteEvent(event.id, userId);
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
