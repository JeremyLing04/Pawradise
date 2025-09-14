import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames; // 改为 Map 类型
  final String lastMessage;
  final String lastMessageType; // 新增：最后消息类型
  final Timestamp lastMessageTime;
  final int unreadCount;
  final String lastMessageSenderId;
  final Timestamp createdAt; // 新增：创建时间

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
    
    // 处理 participantNames，兼容旧数据格式
    Map<String, String> participantNamesMap = {};
    final participantNamesData = data['participantNames'];
    
    if (participantNamesData is Map) {
      participantNamesMap = Map<String, String>.from(participantNamesData);
    } else if (participantNamesData is List) {
      // 兼容旧格式：List<String>
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

  // 获取对方用户ID（当前用户以外的参与者）
  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // 获取对方用户名
  String getOtherUserName(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);
    return participantNames[otherUserId] ?? 'Unknown';
  }

  // 检查是否是未读消息（来自对方）
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
  final String type; // 消息类型：text, image
  final Timestamp timestamp;
  final bool read; // 新增：已读状态

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

  // 辅助方法：检查是否是图片消息
  bool get isImage => type == 'image';

  // 辅助方法：检查是否是文本消息
  bool get isText => type == 'text';

  // 辅助方法：检查消息是否已读
  bool get isRead => read;

  // 辅助方法：获取发送时间
  DateTime get sentTime => timestamp.toDate();

  // 辅助方法：格式化时间显示
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