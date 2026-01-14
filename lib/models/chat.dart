class ChatRoom {
  final String id;
  final String userId;
  final String userName;
  final String adminId;
  final String adminName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.userId,
    required this.userName,
    required this.adminId,
    required this.adminName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(String id, Map<dynamic, dynamic> json) {
    return ChatRoom(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      adminId: json['adminId'] ?? '',
      adminName: json['adminName'] ?? '',
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'adminId': adminId,
      'adminName': adminName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  factory ChatMessage.fromJson(String id, Map<dynamic, dynamic> json) {
    return ChatMessage(
      id: id,
      chatRoomId: json['chatRoomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type.toString().split('.').last,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}

enum MessageType {
  text,
  image,
  notification,
}
