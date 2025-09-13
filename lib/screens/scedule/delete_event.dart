import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';

class DeleteEventDialog extends StatelessWidget {
  final Event event;

  const DeleteEventDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Event'),
      content: const Text('Are you sure you want to delete this event?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final userId = FirebaseAuth.instance.currentUser!.uid;
            Provider.of<EventProvider>(
              context,
              listen: false,
            ).deleteEvent(event.id, userId); // 传 userId
            Navigator.pop(context);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
