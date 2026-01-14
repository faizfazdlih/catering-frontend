import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  List<ChatRoom> _chatRooms = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  // Load chat rooms for a user
  Stream<List<ChatRoom>> getChatRoomsStream(String userId, bool isAdmin) {
    return _chatService.getChatRoomsStream(userId, isAdmin);
  }

  // Load messages for a chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    return _chatService.getMessagesStream(chatRoomId);
  }

  // Create or get chat room
  Future<String?> createOrGetChatRoom({
    required String userId,
    required String userName,
    required String adminId,
    required String adminName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final chatRoomId = await _chatService.createOrGetChatRoom(
        userId: userId,
        userName: userName,
        adminId: adminId,
        adminName: adminName,
      );

      _isLoading = false;
      notifyListeners();
      
      return chatRoomId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    try {
      await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        type: type,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatRoomId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete chat room
  Future<bool> deleteChatRoom(String chatRoomId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _chatService.deleteChatRoom(chatRoomId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load unread count
  Future<void> loadUnreadCount(String userId, bool isAdmin) async {
    try {
      _unreadCount = await _chatService.getUnreadCount(userId, isAdmin);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
