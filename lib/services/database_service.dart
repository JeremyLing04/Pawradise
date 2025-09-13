import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/event_provider.dart';
import '../../services/notification_service.dart';
import '../screens/schedule/calendar_screen.dart';
import '../../constants.dart';
import '../screens/schedule/add_event.dart';
import 'package:timezone/data/latest.dart' as tz;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Initialize notification service
    tz.initializeTimeZones();
    NotificationService().initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    eventProvider.initialize(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CalendarView(
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date; // 更新选中的日期
          });
        },
      ), // 只显示日历视图
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEventDialog(selectedDate: _selectedDate);
      },
    );
  }
}
