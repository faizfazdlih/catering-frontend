import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/chat.dart';
import '../services/chat_provider.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String? _userId;
  String? _userName;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final role = prefs.getString('role');
    
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      setState(() {
        _userId = userData['id']?.toString() ?? userData['_id']?.toString();
        _userName = userData['nama'] ?? userData['username'] ?? 'User';
        _isAdmin = role == 'admin';
        _isLoading = false;
      });
      
      // Debug: Print userId untuk melihat ID yang digunakan
      print('Chat - User ID: $_userId, Role: $role, Name: $_userName');
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
        ),
        body: const Center(
          child: Text('Silakan login terlebih dahulu'),
        ),
      );
    }

    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Pesan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: chatProvider.getChatRoomsStream(_userId!, _isAdmin),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      size: 64,
                      color: Colors.orange[300],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum ada percakapan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      _isAdmin
                          ? 'Pesan dari pelanggan akan muncul di sini'
                          : 'Klik tombol di bawah untuk mulai chat',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final displayName = _isAdmin 
                  ? (chatRoom.userName.isNotEmpty ? chatRoom.userName : 'User') 
                  : (chatRoom.adminName.isNotEmpty ? chatRoom.adminName : 'Admin');
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(0xFF9E090F),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey[900],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      chatRoom.lastMessage ?? 'Belum ada pesan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: chatRoom.unreadCount > 0 
                            ? Colors.grey[700] 
                            : Colors.grey[500],
                        fontWeight: chatRoom.unreadCount > 0 
                            ? FontWeight.w500 
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTimestamp(chatRoom.lastMessageTime),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: chatRoom.unreadCount > 0 
                              ? Colors.black 
                              : Colors.grey[500],
                        ),
                      ),
                      if (chatRoom.unreadCount > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9E090F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chatRoom.unreadCount > 99 
                                ? '99+' 
                                : chatRoom.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chatRoomId: chatRoom.id,
                          chatRoomName: displayName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: !_isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Create or get chat room with admin
                // PENTING: Pastikan adminId ini sesuai dengan ID admin di database
                // Anda bisa mengecek ID admin dengan login sebagai admin dan melihat log
                final chatRoomId = await chatProvider.createOrGetChatRoom(
                  userId: _userId!,
                  userName: _userName ?? 'User',
                  adminId: 'admin_default', // Gunakan ID yang sesuai dengan admin di database
                  adminName: 'Admin Catering',
                );

                if (chatRoomId != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        chatRoomId: chatRoomId,
                        chatRoomName: 'Admin Catering',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal membuat chat room'),
                      backgroundColor: Color(0xFF9E090F),
                    ),
                  );
                }
              },
              backgroundColor: const Color(0xFF9E090F),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.message_rounded),
              label: const Text(
                'Chat Admin',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              elevation: 4,
            )
          : null,
    );
  }
}
