// studentbrigade/lib/services/adapter.dart
/*
import 'package:cloud_firestore/cloud_firestore.dart';

class Adapter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // === USER OPERATIONS ===
  Future<Map<String, dynamic>> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }
  
  Future<void> updateUser(Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(userData['id']).set(userData);
  }
  
  // === CHAT OPERATIONS ===
  Future<void> saveChatMessage(ChatMessage message) async {
    await _firestore.collection('chat_messages').add(message.toJson());
  }
  
  Future<List<Map<String, dynamic>>> getChatMessages() async {
    final query = await _firestore
        .collection('chat_messages')
        .orderBy('timestamp')
        .get();
    return query.docs.map((doc) => doc.data()).toList();
  }
  
  // === VIDEO OPERATIONS ===
  Future<List<Map<String, dynamic>>> getVideos() async {
    final query = await _firestore.collection('videos').get();
    return query.docs.map((doc) => doc.data()).toList();
  }
  
  // === BRIGADIER OPERATIONS ===
  Future<List<Map<String, dynamic>>> getNearbyBrigadiers(double lat, double lng) async {
    // Lógica geolocalizada con Firebase
    final query = await _firestore.collection('brigadiers').get();
    return query.docs.map((doc) => doc.data()).toList();
  }
}
*/