import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames; 
  final String lastMessage;
  final String lastMessageType; 
  final Timestamp lastMessageTime;
  final int unreadCount;
  final String lastMessageSenderId;
  final Timestamp createdAt; 

  ChatRoom({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.lastMessageSenderId,
    required this.createdAt,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    Map<String, String> participantNamesMap = {};
    final participantNamesData = data['participantNames'];
    
    if (participantNamesData is Map) {
      participantNamesMap = Map<String, String>.from(participantNamesData);
    } else if (participantNamesData is List) {
      final participantIds = List<String>.from(data['participantIds'] ?? []);
      final namesList = List<String>.from(participantNamesData);
      for (int i = 0; i < participantIds.length && i < namesList.length; i++) {
        participantNamesMap[participantIds[i]] = namesList[i];
      }
    }
    
    return ChatRoom(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames: participantNamesMap,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageType: data['lastMessageType'] ?? 'text',
      lastMessageTime: data['lastMessageTime'] ?? Timestamp.now(),
      unreadCount: (data['unreadCount'] ?? 0).toInt(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'lastMessageSenderId': lastMessageSenderId,
      'createdAt': createdAt,
    };
  }

  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String getOtherUserName(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);
    return participantNames[otherUserId] ?? 'Unknown';
  }
  bool hasUnreadMessages(String currentUserId) {
    return unreadCount > 0 && lastMessageSenderId != currentUserId;
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final String type;
  final Timestamp timestamp;
  final bool read; 

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'timestamp': timestamp,
      'read': read,
    };
  }

  bool get isImage => type == 'image';

  bool get isText => type == 'text';

  bool get isRead => read;

  DateTime get sentTime => timestamp.toDate();

  String formatTime() {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}