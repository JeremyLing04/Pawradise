import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/event_provider.dart';
import '../../services/notification_service.dart';
import 'calendar_screen.dart';
import '../../constants.dart';
import 'add_event.dart';
import 'package:timezone/data/latest.dart' as tz;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Currently selected date on the calendar
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Initialize time zones and notification service
    tz.initializeTimeZones();
    NotificationService().initialize();

    // Load user events after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.initialize(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only show the calendar view
      body: CalendarView(
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
      ),
      // Floating action button to add new event
      floatingActionButton: FloatingActionButton(
        heroTag: UniqueKey(),
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppColors.accent.withOpacity(0.7),
        foregroundColor: AppColors.background,
        shape: const CircleBorder(), // Ensures perfect circle
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Show dialog to add a new event on the selected date
  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEventDialog(selectedDate: _selectedDate);
      },
    );
  }
}
