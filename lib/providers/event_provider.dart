//providers/event_provider,
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/community_service.dart';

class EventProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final CommunityService _communityService = CommunityService();

  List<Event> _events = [];
  List<Event> get events => _events;

  static final List<int> notificationTimeOptions = [0, 5, 10, 15, 30, 60, 120];

  Future<void> initialize(String userId) async {
    await _notificationService.requestPermissions();
    await loadEvents(userId);
  }

  Future<void> loadEvents(String userId) async {
    _events = await _firestoreService.getEvents(userId);
    notifyListeners();
  }

  Future<void> addEvent(Event event, {bool shareToCommunity = false}) async {
    await _firestoreService.addEvent(event);

    if (!event.isCompleted) {
      final notificationTime = event.scheduledTime.subtract(
        Duration(minutes: event.notificationMinutes),
      );

      await _notificationService.scheduleNotification(
        id: event.id.hashCode,
        title: 'Reminder: ${event.title}',
        body: event.description ?? 'Time for ${event.type.displayName}',
        scheduledTime: notificationTime,
      );
    }
    if (shareToCommunity) {
      await _communityService.shareEventToCommunity(event);
    }

    _events.add(event);
    notifyListeners();
  }

  Future<void> updateEvent(Event event) async {
    await _firestoreService.updateEvent(event);

    await _notificationService.cancelNotification(event.id.hashCode);

    if (!event.isCompleted) {
      final notificationTime = event.scheduledTime.subtract(
        Duration(minutes: event.notificationMinutes),
      );

      await _notificationService.scheduleNotification(
        id: event.id.hashCode,
        title: 'Reminder: ${event.title}',
        body: event.description ?? 'Time for ${event.type.displayName}',
        scheduledTime: notificationTime,
      );
    }

    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id, String userId) async {
    await _firestoreService.deleteEvent(userId, id);
    await _notificationService.cancelNotification(id.hashCode);

    _events.removeWhere((event) => event.id == id);
    notifyListeners();
  }

  Future<List<Event>> getEventsByDate(DateTime date) async {
    return _events
        .where(
          (event) =>
              event.scheduledTime.year == date.year &&
              event.scheduledTime.month == date.month &&
              event.scheduledTime.day == date.day,
        )
        .toList();
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

  Future<void> loadJoinedEvents(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('joined_events')
          .get();

      final joinedEvents = snapshot.docs.map((doc) {
        final data = doc.data();
        return Event.fromMap(data);
      }).toList();

      _events.addAll(joinedEvents);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading joined events: $e');
    }
  }
}
