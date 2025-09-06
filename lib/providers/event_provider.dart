import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class EventProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Event> _events = [];
  List<Event> get events => _events;

  Future<void> loadEvents() async {
    final eventsData = await _databaseService.getEvents();
    _events = eventsData.map((data) => Event.fromMap(data)).toList();
    notifyListeners();
  }

  Future<void> addEvent(Event event) async {
    await _databaseService.insertEvent(event.toMap());

    // 安排通知
    await _notificationService.scheduleNotification(
      id: event.id.hashCode,
      title: 'Reminder: ${event.title}',
      body: event.description ?? 'Time for ${event.type.displayName}',
      scheduledTime: event.scheduledTime.subtract(const Duration(minutes: 30)),
    );

    _events.add(event);
    notifyListeners();
  }

  Future<void> updateEvent(Event event) async {
    await _databaseService.updateEvent(event.toMap());

    // 更新通知
    await _notificationService.cancelNotification(event.id.hashCode);
    await _notificationService.scheduleNotification(
      id: event.id.hashCode,
      title: 'Reminder: ${event.title}',
      body: event.description ?? 'Time for ${event.type.displayName}',
      scheduledTime: event.scheduledTime.subtract(const Duration(minutes: 30)),
    );

    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    await _databaseService.deleteEvent(id);
    await _notificationService.cancelNotification(id.hashCode);

    _events.removeWhere((event) => event.id == id);
    notifyListeners();
  }

  Future<List<Event>> getEventsByDate(DateTime date) async {
    final eventsData = await _databaseService.getEventsByDate(date);
    return eventsData.map((data) => Event.fromMap(data)).toList();
  }
}
