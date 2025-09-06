import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          final upcomingEvents = eventProvider.events
              .where((event) => event.scheduledTime.isAfter(DateTime.now()))
              .toList();

          if (upcomingEvents.isEmpty) {
            return const Center(
              child: Text('No upcoming reminders'),
            );
          }

          return ListView.builder(
            itemCount: upcomingEvents.length,
            itemBuilder: (context, index) {
              final event = upcomingEvents[index];
              return ReminderItem(event: event);
            },
          );
        },
      ),
    );
  }
}

class ReminderItem extends StatelessWidget {
  final Event event;

  const ReminderItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(event.type.icon, color: AppColors.primary),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, yyyy - hh:mm a').format(event.scheduledTime)),
            if (event.description != null) Text(event.description!),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteEvent(context),
        ),
      ),
    );
  }

  void _deleteEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: const Text('Are you sure you want to delete this reminder?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<EventProvider>(context, listen: false).deleteEvent(event.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}