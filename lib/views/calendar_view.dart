import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import 'package:provider/provider.dart';
import '../constants.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

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
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEventDialog(context),
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
      child: ListTile(
        leading: Icon(event.type.icon, color: AppColors.primary),
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
                _deleteEvent(event, context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteEvent(Event event, BuildContext context) {
    Provider.of<EventProvider>(context, listen: false).deleteEvent(event.id);
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEventDialog(selectedDate: _selectedDay ?? DateTime.now());
      },
    );
  }
}

class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;

  const AddEventDialog({super.key, required this.selectedDate});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  EventType _selectedType = EventType.other;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              DropdownButtonFormField<EventType>(
                value: _selectedType,
                items: EventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Event Type'),
              ),
              ListTile(
                title: Text(
                  'Date: ${DateFormat('MMM d, yyyy').format(widget.selectedDate)}',
                ),
                subtitle: Text(
                  'Time: ${DateFormat('hh:mm a').format(_selectedTime)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _saveEvent(context),
          child: const Text('Save'),
        ),
      ],
    );
  }

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

  void _saveEvent(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final event = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user_id', // 在实际应用中从认证系统获取
        petId: 'default_pet_id', // 从宠物选择器获取
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        type: _selectedType,
        scheduledTime: _selectedTime,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      Provider.of<EventProvider>(context, listen: false).addEvent(event);
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
