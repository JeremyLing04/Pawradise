//models/event_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Event {
  final String id;
  final String userId;
  final String petId;
  final String title;
  final String? description;
  final EventType type;
  final DateTime scheduledTime;
  final bool isCompleted;
  final DateTime createdAt;
  final int notificationMinutes;
  final bool sharedToCommunity;

  Event({
    required this.id,
    required this.userId,
    required this.petId,
    required this.title,
    this.description,
    required this.type,
    required this.scheduledTime,
    this.isCompleted = false,
    required this.createdAt,
    this.notificationMinutes = 30,
    this.sharedToCommunity = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'petId': petId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': Timestamp.fromDate(createdAt),
      'notificationMinutes': notificationMinutes,
      'sharedToCommunity': sharedToCommunity ? 1 : 0,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      userId: map['userId'],
      petId: map['petId'],
      title: map['title'],
      description: map['description'],
      type: EventType.values.firstWhere(
        (e) => e.toString() == 'EventType.${map['type']}',
        orElse: () => EventType.other,
      ),
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime']),
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      notificationMinutes: map['notificationMinutes'] ?? 30,
      sharedToCommunity: map['sharedToCommunity'] == 1,
    );
  }
}

enum EventType { vet, feeding, walk, medication, grooming, training, other }

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.vet:
        return 'Vet Appointment';
      case EventType.feeding:
        return 'Feeding';
      case EventType.walk:
        return 'Walk';
      case EventType.medication:
        return 'Medication';
      case EventType.grooming:
        return 'Grooming';
      case EventType.training:
        return 'Training';
      case EventType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.vet:
        return Icons.local_hospital;
      case EventType.feeding:
        return Icons.restaurant;
      case EventType.walk:
        return Icons.directions_walk;
      case EventType.medication:
        return Icons.medication;
      case EventType.grooming:
        return Icons.clean_hands;
      case EventType.training:
        return Icons.sports_martial_arts;
      case EventType.other:
        return Icons.event;
    }
  }
}