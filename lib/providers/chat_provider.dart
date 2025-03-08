// lib/providers/chat_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart'; // Add this import

class ChatProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  final AuthService _authService = AuthService(); // Create internal instance
  final MessageService _messageService = MessageService();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  StreamSubscription? _messagesSubscription;
  
  // Constructor now accepts AuthProvider
  ChatProvider(this._authProvider) {
    _initializeMessages();
  }
  
  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  
  // Initialize messages stream
  void _initializeMessages() async {
    _setLoading(true);
    
    // Get current user from the provider
    final user = _authProvider.user;
    if (user != null) {
      // Listen to messages for this user
      _messagesSubscription = _messageService.getMessages(user.uid).listen((messages) {
        _messages = messages;
        notifyListeners();
      });
    }
    
    _setLoading(false);
  }
  
  // Send a message
  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty) return false;
    
    try {
      _setSending(true);
      
      // Get the current user from the provider
      final user = _authProvider.user;
      if (user == null) return false;
      
      // Get Bizichat user ID
      final appUser = await _authService.getUserData(user.uid);
      if (appUser == null || appUser.bizichatUserId.isEmpty) {
        print('No Bizichat user ID found for the current user');
        
        // Try to ensure Bizichat user exists
        final bizichatId = await _authService.ensureBizichatUser();
        if (bizichatId == null) {
          _setSending(false);
          return false;
        }
      }
      
      // Get the latest user data (might have been updated with a new Bizichat ID)
      final updatedUser = await _authService.getUserData(user.uid);
      if (updatedUser == null) {
        _setSending(false);
        return false;
      }
      
      // Send message to Bizichat
      bool messageSent = await _messageService.sendMessage(text, updatedUser.bizichatUserId);
      if (messageSent) {
        // Poll for AI response
        final aiResponse = await _messageService.pollForAIResponse(updatedUser.bizichatUserId);
        if (aiResponse != null) {
          // Messages will be updated via the stream
        }
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    } finally {
      _setSending(false);
    }
  }
  
  // Clear chat history
  Future<void> clearChat() async {
    try {
      _setLoading(true);
      await _messageService.clearChat();
      _setLoading(false);
    } catch (e) {
      print('Error clearing chat: $e');
      _setLoading(false);
    }
  }
  
  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // Set sending state
  void _setSending(bool value) {
    _isSending = value;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}