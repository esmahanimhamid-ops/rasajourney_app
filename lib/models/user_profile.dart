import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.photoUrl,
    required this.bio,
    required this.hometown,
    required this.phone,
    required this.createdAt,
    required this.lastSeenAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final String photoUrl;
  final String bio;
  final String hometown;
  final String phone;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  factory UserProfile.fromSources(
    User user,
    Map<String, dynamic>? data,
  ) {
    final email = _normalizedText(data?['email']) ?? user.email ?? '';
    final fullName = _normalizedText(data?['fullName']) ??
        _normalizedText(user.displayName) ??
        _emailPrefix(email);

    return UserProfile(
      uid: user.uid,
      email: email,
      fullName: fullName,
      photoUrl: _normalizedText(data?['photoUrl']) ?? user.photoURL ?? '',
      bio: _normalizedText(data?['bio']) ?? '',
      hometown: _normalizedText(data?['hometown']) ?? '',
      phone: _normalizedText(data?['phone']) ?? '',
      createdAt: _toDateTime(data?['createdAt']),
      lastSeenAt: _toDateTime(data?['lastSeenAt']),
    );
  }

  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : 'Food Explorer';

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) {
      return 'FE';
    }

    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'FE';
    }

    if (parts.length == 1) {
      final sliceLength = parts.first.length >= 2 ? 2 : 1;
      final value = parts.first.substring(0, sliceLength);
      return value.toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get headline {
    if (bio.isNotEmpty) {
      return bio;
    }

    if (hometown.isNotEmpty) {
      return 'Based in $hometown and always chasing the next memorable bite.';
    }

    return 'Saving the best flavours, reviews, and hidden gems in one place.';
  }

  bool get hasDetails =>
      bio.isNotEmpty || hometown.isNotEmpty || phone.isNotEmpty;

  static String? _normalizedText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  static String _emailPrefix(String email) {
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return email;
  }
}
