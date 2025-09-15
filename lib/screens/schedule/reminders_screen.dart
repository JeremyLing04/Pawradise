// screens/schedule/reminders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import 'delete_event.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        title: const Text('Reminders'),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.accent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Consumer<EventProvider>(
          builder: (context, eventProvider, child) {
            // Filter upcoming events (after current time)
            final upcomingEvents = eventProvider.events
                .where((event) => event.scheduledTime.isAfter(DateTime.now()))
                .toList();

            if (upcomingEvents.isEmpty) {
              return Center(
                child: Text(
                  'No upcoming reminders 🎈',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              );
            }

            // Display upcoming events in a scrollable list
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = upcomingEvents[index];
                return ReminderItem(event: event);
              },
            );
          },
        ),
      ),
    );
  }
}

// Individual reminder item
class ReminderItem extends StatelessWidget {
  final Event event;

  const ReminderItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: AppColors.accent, width: 2),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        // Event type icon
        leading: Icon(
          event.type.icon,
          color: AppColors.accent,
          size: 32,
        ),
        // Event title
        title: Text(
          event.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // Event date/time and optional description
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, yyyy - hh:mm a').format(event.scheduledTime),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            if (event.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  event.description!,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
        // Delete button
        trailing: IconButton(
          icon: Icon(Icons.delete, color: AppColors.accent, size: 26),
          onPressed: () => _deleteEvent(context),
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  void _deleteEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteEventDialog(event: event);
      },
    );
  }
}
