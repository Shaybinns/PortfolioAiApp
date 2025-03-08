// lib/models/message.dart - Updated to match your existing structure with needed properties
class Message {
  final String id;
  final String text;  // Keep 'text' instead of 'content' to match your existing code
  final DateTime timestamp;
  final bool sentByUser;  // Keep 'sentByUser' instead of 'isAI' to match your existing code
  final String userId;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.sentByUser,
    required this.userId,
  });

  // Create a Message from a Firestore document
  factory Message.fromMap(Map<String, dynamic> map, String docId) {
    return Message(
      id: docId,
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null 
                ? map['timestamp'] is DateTime 
                  ? map['timestamp'] 
                  : DateTime.fromMillisecondsSinceEpoch(map['timestamp'].millisecondsSinceEpoch)
                : DateTime.now(),
      sentByUser: map['sentByUser'] ?? false,
      userId: map['userId'] ?? '',
    );
  }

  // Convert a Message object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'timestamp': timestamp,
      'sentByUser': sentByUser,
      'userId': userId,
    };
  }
}