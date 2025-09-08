import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class EventProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Event> _events = [];
  List<Event> get events => _events;

  static final List<int> notificationTimeOptions = [0, 5, 10, 15, 30, 60, 120];

  // initial
  Future<void> initialize() async {
    await _notificationService.requestPermissions();
    await loadEvents();
  }

  Future<void> loadEvents() async {
    final eventsData = await _databaseService.getEvents();
    _events = eventsData.map((data) => Event.fromMap(data)).toList();
    notifyListeners();
  }

  Future<void> addEvent(Event event) async {
    await _databaseService.insertEvent(event.toMap());

    final notificationTime = event.scheduledTime.subtract(
      Duration(minutes: event.notificationMinutes),
    );

    await _notificationService.scheduleNotification(
      id: event.id.hashCode,
      title: 'Reminder: ${event.title}',
      body: event.description ?? 'Time for ${event.type.displayName}',
      scheduledTime: notificationTime,
    );

    _events.add(event);
    notifyListeners();
  }

  Future<void> updateEvent(Event event) async {
    await _databaseService.updateEvent(event.toMap());

    await _notificationService.cancelNotification(event.id.hashCode);

    final notificationTime = event.scheduledTime.subtract(
      Duration(minutes: event.notificationMinutes),
    );

    await _notificationService.scheduleNotification(
      id: event.id.hashCode,
      title: 'Reminder: ${event.title}',
      body: event.description ?? 'Time for ${event.type.displayName}',
      scheduledTime: notificationTime,
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

  Future<void> clearAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  static String getNotificationTimeText(int minutes) {
    if (minutes == 0) return 'Notify on time';
    if (minutes < 60) return '$minutes minutes early';
    if (minutes == 60) return '1 hour';
    return '${minutes ~/ 60} hours ${minutes % 60} minutes early';
  }
}
