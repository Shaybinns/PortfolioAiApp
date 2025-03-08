// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'bizichat_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BizichatService _bizichatService = BizichatService();

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      // 1. Create Firebase user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // 2. Create Bizichat user and get the contact ID
        String displayName = email.split('@').first;
        String? bizichatUserId = await _bizichatService.createUser(displayName, email);
        
        // 3. Create user document in Firestore with the Bizichat user ID
        await _createUserInFirestore(
          userCredential.user!,
          bizichatUserId ?? ''
        );
      }
      
      return userCredential.user;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserInFirestore(User user, String bizichatUserId) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'bizichatUserId': bizichatUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Bizichat user ID
  Future<void> updateBizichatUserId(String uid, String bizichatUserId) async {
    await _firestore.collection('users').doc(uid).update({
      'bizichatUserId': bizichatUserId,
    });
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Ensure Bizichat user exists for current user
  Future<String?> ensureBizichatUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    try {
      // Get current user data
      final appUser = await getUserData(user.uid);
      
      // If Bizichat user ID exists, return it
      if (appUser != null && appUser.bizichatUserId.isNotEmpty) {
        return appUser.bizichatUserId;
      }
      
      // If no Bizichat user ID, create one
      final displayName = user.email?.split('@').first ?? '';
      final bizichatUserId = await _bizichatService.createUser(
        displayName, 
        user.email ?? ''
      );
      
      // If creation successful, update user record and return ID
      if (bizichatUserId != null) {
        await updateBizichatUserId(user.uid, bizichatUserId);
        return bizichatUserId;
      }
      
      return null;
    } catch (e) {
      print('Ensure Bizichat user error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}