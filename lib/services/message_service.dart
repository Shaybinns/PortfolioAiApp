// lib/services/message_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import 'bizichat_service.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BizichatService _bizichatService = BizichatService();
  
  // Get messages for the current user
  Stream<List<Message>> getMessages(String userId) {
    return _firestore
        .collection('messages')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Send a message to Bizichat
  Future<bool> sendMessage(String text, String bizichatUserId) async {
    try {
      // Save the message to Firestore
      final messageId = await _saveMessage(text, true);
      
      if (messageId != null) {
        // Store the message in Bizichat
        return await _bizichatService.storeUserInput(bizichatUserId, text);
      }
      
      return false;
    } catch (e) {
      print('Send message error: $e');
      return false;
    }
  }
  
  // Poll for AI response
  Future<Message?> pollForAIResponse(String bizichatUserId) async {
    try {
      // Trigger the flow to generate a response
      final triggered = await _bizichatService.triggerFlow(bizichatUserId);
      if (!triggered) {
        print('Failed to trigger flow');
        return null;
      }
      
      // Poll for a response with timeout
      int attempts = 0;
      const maxAttempts = 10;
      
      while (attempts < maxAttempts) {
        await Future.delayed(Duration(milliseconds: 500));
        
        final responseText = await _bizichatService.getLatestAIResponse(bizichatUserId);
        if (responseText != null && responseText.isNotEmpty) {
          // Save the AI response to Firestore
          final messageId = await _saveMessage(responseText, false);
          
          if (messageId != null) {
            // Create a message from the stored message ID
            return Message(
              id: messageId,
              text: responseText,
              timestamp: DateTime.now(),
              sentByUser: false,
              userId: 'bizichat_ai',
            );
          }
        }
        
        attempts++;
      }
      
      print('Timed out waiting for AI response');
      return null;
    } catch (e) {
      print('Poll for AI response error: $e');
      return null;
    }
  }
  
  // Save a message to Firestore
  Future<String?> _saveMessage(String text, bool sentByUser) async {
    try {
      final docRef = await _firestore.collection('messages').add({
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'sentByUser': sentByUser,
        'userId': sentByUser ? 'current_user' : 'bizichat_ai',
      });
      
      return docRef.id;
    } catch (e) {
      print('Save message error: $e');
      return null;
    }
  }
  
  // Clear chat history
  Future<void> clearChat() async {
    try {
      final batch = _firestore.batch();
      final messages = await _firestore
          .collection('messages')
          .get();
          
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Clear chat error: $e');
    }
  }
}