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
      'sharedToCommunity': sharedToCommunity,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    // 处理 scheduledTime - 支持 Timestamp 和 int 两种格式
    DateTime parseScheduledTime(dynamic timeData) {
      if (timeData is Timestamp) {
        return timeData.toDate();
      } else if (timeData is int) {
        return DateTime.fromMillisecondsSinceEpoch(timeData);
      } else {
        return DateTime.now();
      }
    }

    // 处理 createdAt - 支持 Timestamp 和 int 两种格式
    DateTime parseCreatedAt(dynamic timeData) {
      if (timeData is Timestamp) {
        return timeData.toDate();
      } else if (timeData is int) {
        return DateTime.fromMillisecondsSinceEpoch(timeData);
      } else {
        return DateTime.now();
      }
    }

    // 处理 isCompleted - 支持 bool 和 int 两种格式
    bool parseIsCompleted(dynamic completedData) {
      if (completedData is bool) {
        return completedData;
      } else if (completedData is int) {
        return completedData == 1;
      } else {
        return false;
      }
    }

    // 处理 sharedToCommunity - 支持 bool 和 int 两种格式
    bool parseSharedToCommunity(dynamic sharedData) {
      if (sharedData is bool) {
        return sharedData;
      } else if (sharedData is int) {
        return sharedData == 1;
      } else {
        return false;
      }
    }

    return Event(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      petId: map['petId'] ?? 'default_pet_id',
      title: map['title'] ?? '',
      description: map['description'],
      type: EventType.values.firstWhere(
        (e) => e.toString() == 'EventType.${map['type']}',
        orElse: () => EventType.other,
      ),
      scheduledTime: parseScheduledTime(map['scheduledTime']),
      isCompleted: parseIsCompleted(map['isCompleted']),
      createdAt: parseCreatedAt(map['createdAt']),
      notificationMinutes: (map['notificationMinutes'] ?? 30).toInt(),
      sharedToCommunity: parseSharedToCommunity(map['sharedToCommunity']),
    );
  }

  // 添加一个便捷的工厂方法用于从 Firestore 文档创建事件
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event.fromMap({...data, 'id': doc.id});
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