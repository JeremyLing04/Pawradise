//screen/schedule/calendar
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
      backgroundColor: AppColors.accent.withOpacity(0.5),
      appBar: AppBar(
        title: const Text('PawSchedule'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showRemindersView(context),
            tooltip: 'View Reminders',
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(50),
          border: Border.all( 
            color: AppColors.accent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        //calendar
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TableCalendar(
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

                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),

            Divider(
              thickness: 1,
              height: 1,
              color: AppColors.accent, 
            ),

            // list of events
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: _buildEventList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      return const Center(
        child: Text(
          'Select a day to view events',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        final dayEvents = eventProvider.events
            .where((event) => isSameDay(event.scheduledTime, _selectedDay))
            .toList();

        if (dayEvents.isEmpty) {
          return Center(
            child: Text(
              'Looks like ${DateFormat('MMM d, yyyy').format(_selectedDay!)} is free 🎉',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: AppColors.primary, 
        border: Border.all( 
          color: AppColors.accent, 
          width: 2,
      ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withOpacity(0.2),
          child: Icon(event.type.icon, color: AppColors.accent),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          DateFormat('hh:mm a').format(event.scheduledTime),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: event.isCompleted,
            activeColor: AppColors.accent.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            onChanged: (value) =>
                _toggleEventCompletion(event, value!, context),
          ),
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
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide( 
            color: AppColors.accent,
            width: 2,
            ),
          ),
          title: Text(event.title, style: TextStyle(color: AppColors.accent)),
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
