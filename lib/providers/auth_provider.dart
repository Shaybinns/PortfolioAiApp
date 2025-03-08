// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/bizichat_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final BizichatService _bizichatService = BizichatService();
  
  User? _user;
  AppUser? _appUser;
  bool _isLoading = false;
  
  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  AuthProvider() {
    _init();
  }
  
  // Initialize provider
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      
      if (user != null) {
        // Get app user data from Firestore
        _appUser = await _authService.getUserData(user.uid);
        
        // If no Bizichat user ID, create one
        if (_appUser != null && _appUser!.bizichatUserId.isEmpty) {
          await _createBizichatUser(user);
        }
      } else {
        _appUser = null;
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }
  
  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = await _authService.signInWithEmail(email, password);
      
      _isLoading = false;
      notifyListeners();
      
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Sign up
  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = await _authService.signUpWithEmail(email, password);
      
      if (user != null) {
        await _createBizichatUser(user);
      }
      
      _isLoading = false;
      notifyListeners();
      
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Create Bizichat user
  Future<void> _createBizichatUser(User user) async {
    // Create Bizichat user
    final bizichatUserId = await _bizichatService.createUser(
      user.displayName ?? 'User',
      user.email ?? 'user@example.com',
    );
    
    // Update Firestore with Bizichat user ID
    if (bizichatUserId != null) {
      await _authService.updateBizichatUserId(user.uid, bizichatUserId);
      
      // Store Bizichat user ID in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bizichat_user_id', bizichatUserId);
      
      // Update app user
      _appUser = AppUser(
        id: user.uid,
        email: user.email ?? '',
        bizichatUserId: bizichatUserId,
      );
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signOut();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bizichat_user_id');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}