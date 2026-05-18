import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant.dart';

class AdminService {
  AdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Restaurant>> restaurantsStream() {
    return _firestore.collection('restaurants').snapshots().map((snapshot) {
      final restaurants = snapshot.docs
          .map((doc) => Restaurant.fromMap(doc.data(), id: doc.id))
          .where((restaurant) => restaurant.name.trim().isNotEmpty)
          .toList();
      restaurants.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return restaurants;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> categoriesStream() {
    return _firestore.collection('categories').orderBy('name').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> reviewsStream() {
    return _firestore
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> saveRestaurant({
    String? id,
    required Restaurant restaurant,
  }) async {
    final docRef = id == null || id.isEmpty
        ? _firestore.collection('restaurants').doc()
        : _firestore.collection('restaurants').doc(id);

    await docRef.set({
      'placeId': restaurant.placeId,
      'name': restaurant.name,
      'address': restaurant.address,
      'locationText': restaurant.address,
      'image': restaurant.image,
      'imageUrl': restaurant.image,
      'galleryImages': restaurant.galleryImages,
      'lat': restaurant.lat,
      'lng': restaurant.lng,
      'location': GeoPoint(restaurant.lat, restaurant.lng),
      'rating': restaurant.rating,
      'ratingCount': restaurant.ratingCount,
      'reviews': restaurant.reviews,
      'operatingHours': restaurant.operatingHours,
      'isOpen': restaurant.isOpen,
      'status': restaurant.status,
      'restaurantType': restaurant.restaurantType,
      'halalStatus': restaurant.halalStatus,
      'menuItems': restaurant.menuItems,
      'updatedAt': FieldValue.serverTimestamp(),
      if (id == null || id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteRestaurant(String restaurantId) {
    return _firestore.collection('restaurants').doc(restaurantId).delete();
  }

  Future<void> saveCategory(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return;
    }

    final categoryId = normalizedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    await _firestore.collection('categories').doc(categoryId).set({
      'name': normalizedName,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String categoryId) {
    return _firestore.collection('categories').doc(categoryId).delete();
  }

  Future<void> deleteReview(
    Map<String, dynamic> reviewData,
    String docId,
  ) async {
    final reviewId = (reviewData['reviewId'] ?? docId).toString();
    final userId = reviewData['userId']?.toString() ?? '';
    final restaurantId = reviewData['restaurantId']?.toString() ?? '';
    final batch = _firestore.batch();

    batch.delete(_firestore.collection('reviews').doc(reviewId));

    if (userId.isNotEmpty) {
      batch.delete(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('reviews')
            .doc(reviewId),
      );
    }

    if (restaurantId.isNotEmpty) {
      batch.delete(
        _firestore
            .collection('restaurants')
            .doc(restaurantId)
            .collection('userReviews')
            .doc(reviewId),
      );
    }

    await batch.commit();
  }
}
