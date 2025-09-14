//screen/schedule/calender
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import 'edit_event.dart';
import 'delete_event.dart';
import 'reminders_screen.dart';

class CalendarView extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  const CalendarView({super.key, this.onDateSelected});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showRemindersView(context),
            tooltip: 'View Reminders',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // 通知父组件日期选择变化
              if (widget.onDateSelected != null) {
                widget.onDateSelected!(selectedDay);
              }
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) => _getEventsForDay(day, context),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  // 显示提醒视图
  void _showRemindersView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RemindersView()),
    );
  }

  List<Event> _getEventsForDay(DateTime day, BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    return eventProvider.events
        .where((event) => isSameDay(event.scheduledTime, day))
        .toList();
  }

  Widget _buildEventList() {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a day to view events'));
    }

    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        final dayEvents = eventProvider.events
            .where((event) => isSameDay(event.scheduledTime, _selectedDay))
            .toList();

        if (dayEvents.isEmpty) {
          return Center(
            child: Text(
              'No events for ${DateFormat('MMM d, yyyy').format(_selectedDay!)}',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: dayEvents.length,
          itemBuilder: (context, index) {
            final event = dayEvents[index];
            return _buildEventItem(event, context);
          },
        );
      },
    );
  }

  Widget _buildEventItem(Event event, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppColors.secondary,
      child: ListTile(
        leading: Icon(event.type.icon, color: AppColors.accent),
        title: Text(event.title),
        subtitle: Text(DateFormat('hh:mm a').format(event.scheduledTime)),
        trailing: Checkbox(
          value: event.isCompleted,
          onChanged: (value) => _toggleEventCompletion(event, value!, context),
        ),
        onTap: () => _showEventDetails(event, context),
      ),
    );
  }

  void _toggleEventCompletion(
    Event event,
    bool completed,
    BuildContext context,
  ) {
    final updatedEvent = Event(
      id: event.id,
      userId: event.userId,
      petId: event.petId,
      title: event.title,
      description: event.description,
      type: event.type,
      scheduledTime: event.scheduledTime,
      isCompleted: completed,
      createdAt: event.createdAt,
      notificationMinutes: event.notificationMinutes,
    );

    Provider.of<EventProvider>(
      context,
      listen: false,
    ).updateEvent(updatedEvent);
  }

  void _showEventDetails(Event event, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event.title),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${event.type.displayName}'),
              Text(
                'Time: ${DateFormat('MMM d, yyyy - hh:mm a').format(event.scheduledTime)}',
              ),
              if (event.description != null)
                Text('Description: ${event.description}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _editEvent(event, context);
              },
              child: const Text('Edit', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteEvent(event, context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _editEvent(Event event, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditEventDialog(event: event);
      },
    );
  }

  void _deleteEvent(Event event, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteEventDialog(event: event);
      },
    );
  }
}
