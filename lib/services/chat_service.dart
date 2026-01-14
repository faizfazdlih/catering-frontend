import 'package:firebase_database/firebase_database.dart';
import '../models/chat.dart';

class ChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get chat rooms stream for a user
  Stream<List<ChatRoom>> getChatRoomsStream(String userId, bool isAdmin) {
    print('ChatService - Getting chat rooms for userId: $userId, isAdmin: $isAdmin');
    
    // Jika admin, ambil SEMUA chat rooms tanpa filter
    if (isAdmin) {
      return _database
          .child('chatRooms')
          .onValue
          .map((event) {
        final List<ChatRoom> chatRooms = [];
        
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          print('ChatService - Admin found ${data.length} chat rooms');
          data.forEach((key, value) {
            final chatRoom = ChatRoom.fromJson(key, value as Map<dynamic, dynamic>);
            chatRooms.add(chatRoom);
            print('ChatService - ChatRoom: userId=${chatRoom.userId}, adminId=${chatRoom.adminId}');
          });
          
          // Sort by last message time
          chatRooms.sort((a, b) {
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });
        } else {
          print('ChatService - No chat rooms found in database');
        }
        
        return chatRooms;
      });
    }
    
    // Jika client, filter berdasarkan userId
    return _database
        .child('chatRooms')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final List<ChatRoom> chatRooms = [];
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        print('ChatService - Client found ${data.length} chat rooms');
        data.forEach((key, value) {
          chatRooms.add(ChatRoom.fromJson(key, value as Map<dynamic, dynamic>));
        });
        
        // Sort by last message time
        chatRooms.sort((a, b) {
          if (a.lastMessageTime == null) return 1;
          if (b.lastMessageTime == null) return -1;
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        });
      }
      
      return chatRooms;
    });
  }

  // Get messages stream for a chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    return _database
        .child('messages')
        .child(chatRoomId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final List<ChatMessage> messages = [];
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          messages.add(ChatMessage.fromJson(key, value as Map<dynamic, dynamic>));
        });
        
        // Sort by timestamp (oldest first)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      
      return messages;
    });
  }

  // Create or get existing chat room
  Future<String> createOrGetChatRoom({
    required String userId,
    required String userName,
    required String adminId,
    required String adminName,
  }) async {
    print('ChatService - Creating/Getting chat room: userId=$userId, adminId=$adminId');
    
    // Check if chat room already exists
    final snapshot = await _database
        .child('chatRooms')
        .orderByChild('userId')
        .equalTo(userId)
        .once();

    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      print('ChatService - Found existing chat rooms: ${data.length}');
      // Find chat room with matching admin
      for (var entry in data.entries) {
        final chatRoom = entry.value as Map<dynamic, dynamic>;
        if (chatRoom['adminId'] == adminId) {
          print('ChatService - Using existing chat room: ${entry.key}');
          return entry.key;
        }
      }
    }

    // Create new chat room
    final chatRoomRef = _database.child('chatRooms').push();
    final chatRoom = ChatRoom(
      id: chatRoomRef.key!,
      userId: userId,
      userName: userName,
      adminId: adminId,
      adminName: adminName,
      createdAt: DateTime.now(),
    );

    print('ChatService - Creating NEW chat room: ${chatRoomRef.key}');
    print('ChatService - Data: ${chatRoom.toJson()}');
    await chatRoomRef.set(chatRoom.toJson());
    return chatRoomRef.key!;
  }

  // Send message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    final messageRef = _database.child('messages').child(chatRoomId).push();
    
    final chatMessage = ChatMessage(
      id: messageRef.key!,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );

    await messageRef.set(chatMessage.toJson());

    // Update last message in chat room
    await _database.child('chatRooms').child(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTime': chatMessage.timestamp.millisecondsSinceEpoch,
    });

    // Increment unread count for receiver
    final chatRoomSnapshot = await _database.child('chatRooms').child(chatRoomId).once();
    if (chatRoomSnapshot.snapshot.value != null) {
      final chatRoomData = chatRoomSnapshot.snapshot.value as Map<dynamic, dynamic>;
      final currentUnreadCount = chatRoomData['unreadCount'] ?? 0;
      await _database.child('chatRooms').child(chatRoomId).update({
        'unreadCount': currentUnreadCount + 1,
      });
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final snapshot = await _database
        .child('messages')
        .child(chatRoomId)
        .orderByChild('isRead')
        .equalTo(false)
        .once();

    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};
      
      data.forEach((key, value) {
        final message = value as Map<dynamic, dynamic>;
        // Only mark as read if the current user is not the sender
        if (message['senderId'] != userId) {
          updates['messages/$chatRoomId/$key/isRead'] = true;
        }
      });

      if (updates.isNotEmpty) {
        await _database.update(updates);
        
        // Reset unread count in chat room
        await _database.child('chatRooms').child(chatRoomId).update({
          'unreadCount': 0,
        });
      }
    }
  }

  // Delete chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    await _database.child('chatRooms').child(chatRoomId).remove();
    await _database.child('messages').child(chatRoomId).remove();
  }

  // Get unread message count for user
  Future<int> getUnreadCount(String userId, bool isAdmin) async {
    String queryField = isAdmin ? 'adminId' : 'userId';
    
    final snapshot = await _database
        .child('chatRooms')
        .orderByChild(queryField)
        .equalTo(userId)
        .once();

    int totalUnread = 0;
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final chatRoom = value as Map<dynamic, dynamic>;
        totalUnread += (chatRoom['unreadCount'] ?? 0) as int;
      });
    }

    return totalUnread;
  }
}
