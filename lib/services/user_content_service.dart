import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/restaurant.dart';
import 'auth_service.dart';

class UserContentService {
  UserContentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<Set<String>> favouriteIdsStream(String? userId) {
    if (userId == null || userId.isEmpty) {
      return Stream<Set<String>>.value(const <String>{});
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favourites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<bool> toggleFavourite({
    required User user,
    required Restaurant restaurant,
  }) async {
    await AuthService.syncUserProfile(user);

    final favouriteDoc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .doc(restaurant.id);

    final existing = await favouriteDoc.get();

    if (existing.exists) {
      await favouriteDoc.delete();
      return false;
    }

    await favouriteDoc.set({
      'restaurantId': restaurant.id,
      'placeId': restaurant.placeId,
      'name': restaurant.name,
      'address': restaurant.address,
      'image': restaurant.image,
      'lat': restaurant.lat,
      'lng': restaurant.lng,
      'rating': restaurant.rating,
      'ratingCount': restaurant.ratingCount,
      'status': restaurant.status,
      'isOpen': restaurant.isOpen,
      'savedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<void> submitReview({
    required User user,
    required Restaurant restaurant,
    required double rating,
    required String text,
  }) async {
    await AuthService.syncUserProfile(user);

    final reviewId = _firestore.collection('reviews').doc().id;
    final reviewData = {
      'reviewId': reviewId,
      'userId': user.uid,
      'userEmail': user.email,
      'restaurantId': restaurant.id,
      'placeId': restaurant.placeId,
      'restaurantName': restaurant.name,
      'restaurantAddress': restaurant.address,
      'rating': rating,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();

    final userReviewDoc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reviews')
        .doc(reviewId);
    batch.set(userReviewDoc, reviewData);

    final globalReviewDoc = _firestore.collection('reviews').doc(reviewId);
    batch.set(globalReviewDoc, reviewData);

    if (restaurant.id.isNotEmpty) {
      final restaurantReviewDoc = _firestore
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('userReviews')
          .doc(reviewId);
      batch.set(restaurantReviewDoc, reviewData);
    }

    await batch.commit();
  }
}
