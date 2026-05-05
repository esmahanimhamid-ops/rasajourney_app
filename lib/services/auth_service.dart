import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class AuthService {
  AuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  static Stream<UserProfile> userProfileStream(User user) {
    return userDoc(user.uid)
        .snapshots()
        .map((snapshot) => UserProfile.fromSources(user, snapshot.data()));
  }

  static Future<UserProfile> loadUserProfile(User user) async {
    final snapshot = await userDoc(user.uid).get();
    return UserProfile.fromSources(user, snapshot.data());
  }

  static Future<void> syncUserProfile(
    User user, {
    String? fullName,
  }) async {
    final docRef = userDoc(user.uid);
    final snapshot = await docRef.get();
    final providedName = fullName?.trim() ?? '';
    final authDisplayName = user.displayName?.trim() ?? '';
    final existingName = snapshot.data()?['fullName']?.toString().trim() ?? '';
    final normalizedName = providedName.isNotEmpty
        ? providedName
        : authDisplayName.isNotEmpty
            ? authDisplayName
            : existingName;

    await docRef.set({
      'uid': user.uid,
      'email': user.email,
      'fullName': normalizedName,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateUserProfile({
    required User user,
    required String fullName,
    String bio = '',
    String hometown = '',
    String phone = '',
  }) async {
    final normalizedName = fullName.trim();
    final normalizedBio = bio.trim();
    final normalizedHometown = hometown.trim();
    final normalizedPhone = phone.trim();

    if (normalizedName.isNotEmpty &&
        normalizedName != (user.displayName ?? '').trim()) {
      await user.updateDisplayName(normalizedName);
      await _auth.currentUser?.reload();
    }

    await userDoc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'fullName': normalizedName,
      'photoUrl': user.photoURL,
      'bio': normalizedBio,
      'hometown': normalizedHometown,
      'phone': normalizedPhone,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> signOut() => _auth.signOut();
}
