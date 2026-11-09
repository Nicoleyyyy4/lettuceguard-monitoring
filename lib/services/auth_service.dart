import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current authenticated user mapped to UserModel
  UserModel? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return UserModel(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ?? (fbUser.email?.contains('@') == true ? fbUser.email!.split('@')[0] : 'Operator'),
    );
  }

  // Stream for auth state changes if needed
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return UserModel(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? (fbUser.email?.contains('@') == true ? fbUser.email!.split('@')[0] : 'Operator'),
      );
    });
  }

  // Sign In with Email & Password
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      fb_auth.UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      return UserModel(
        uid: user.uid,
        email: user.email ?? email,
        displayName: user.displayName ?? email.split('@')[0],
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register with Name, Email & Password (saves to Auth, Cloud Firestore & Realtime Database)
  Future<UserModel> registerWithEmail(String name, String email, String password) async {
    try {
      // 1. Create user in Firebase Authentication
      fb_auth.UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Update display name in Firebase Auth
      await user.updateDisplayName(name);

      // 2. Save user details to Cloud Firestore in collection 'users' with user's UID as doc ID
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Also sync user profile to Firebase Realtime Database
      await _dbRef.child('users').child(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return UserModel(
        uid: user.uid,
        email: user.email ?? email,
        displayName: name,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}