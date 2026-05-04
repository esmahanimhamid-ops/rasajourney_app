import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/restaurant.dart';
import 'platform_config_service.dart';

class GooglePlaceDetails {
  final String? address;
  final String? imageUrl;
  final double? rating;
  final int? ratingCount;
  final List<String> reviews;
  final List<String> operatingHours;
  final bool? isOpen;
  final String? status;

  const GooglePlaceDetails({
    this.address,
    this.imageUrl,
    this.rating,
    this.ratingCount,
    this.reviews = const [],
    this.operatingHours = const [],
    this.isOpen,
    this.status,
  });
}

class GooglePlacesService {
  GooglePlacesService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Restaurant> enrichRestaurant(Restaurant restaurant) async {
    final placeId = restaurant.placeId;
    if (placeId == null || placeId.isEmpty) {
      return restaurant;
    }

    final details = await fetchPlaceDetails(placeId);
    final enrichedRestaurant = restaurant.copyWith(
      address: _prefer(details.address, restaurant.address),
      image: _prefer(details.imageUrl, restaurant.image),
      rating: details.rating ?? restaurant.rating,
      ratingCount: details.ratingCount ?? restaurant.ratingCount,
      reviews: details.reviews.isNotEmpty ? details.reviews : restaurant.reviews,
      operatingHours: details.operatingHours.isNotEmpty
          ? details.operatingHours
          : restaurant.operatingHours,
      isOpen: details.isOpen ?? restaurant.isOpen,
      status: _prefer(
        _displayStatus(details.status, details.isOpen),
        restaurant.status,
      ),
    );

    if (restaurant.id.isNotEmpty) {
      await _firestore.collection('restaurants').doc(restaurant.id).set({
        if (details.address != null && details.address!.isNotEmpty)
          'address': details.address,
        if (details.address != null && details.address!.isNotEmpty)
          'locationText': details.address,
        if (details.imageUrl != null && details.imageUrl!.isNotEmpty)
          'imageUrl': details.imageUrl,
        if (details.rating != null) 'rating': details.rating,
        if (details.ratingCount != null) 'ratingCount': details.ratingCount,
        if (details.reviews.isNotEmpty) 'reviews': details.reviews,
        if (details.operatingHours.isNotEmpty)
          'operatingHours': details.operatingHours,
        if (details.isOpen != null) 'isOpen': details.isOpen,
        if (details.status != null && details.status!.isNotEmpty)
          'status': details.status,
        'lastPlacesSyncAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return enrichedRestaurant;
  }

  Future<GooglePlaceDetails> fetchPlaceDetails(String placeId) async {
    final apiKey = await PlatformConfigService.getMapsApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Maps API key is not available on this device.');
    }

    final result = await _fetchPlaceResult(
      placeId,
      apiKey: apiKey,
      fields:
          'formatted_address,rating,user_ratings_total,reviews,opening_hours,current_opening_hours,business_status,photos',
      reviewsSort: 'newest',
    );
    final currentOpeningHours =
        result['current_opening_hours'] as Map<String, dynamic>?;
    final regularOpeningHours =
        result['opening_hours'] as Map<String, dynamic>?;
    final currentWeekdayText = _toStringList(currentOpeningHours?['weekday_text']);
    final operatingHours = currentWeekdayText.isNotEmpty
        ? currentWeekdayText
        : _toStringList(regularOpeningHours?['weekday_text']);
    final reviews = ((result['reviews'] as List?) ?? [])
        .map((review) => _formatReview(review as Map<String, dynamic>))
        .where((review) => review.isNotEmpty)
        .take(3)
        .toList();
    final photos = (result['photos'] as List?) ?? const [];

    String? imageUrl;
    if (photos.isNotEmpty) {
      final firstPhoto = photos.first as Map<String, dynamic>;
      final photoReference = firstPhoto['photo_reference']?.toString();
      if (photoReference != null && photoReference.isNotEmpty) {
        imageUrl = Uri.https(
          'maps.googleapis.com',
          '/maps/api/place/photo',
          {
            'maxwidth': '1200',
            'photo_reference': photoReference,
            'key': apiKey,
          },
        ).toString();
      }
    }

    return GooglePlaceDetails(
      address: result['formatted_address']?.toString(),
      imageUrl: imageUrl,
      rating: (result['rating'] as num?)?.toDouble(),
      ratingCount: (result['user_ratings_total'] as num?)?.toInt(),
      reviews: reviews,
      operatingHours: operatingHours,
      isOpen:
          (currentOpeningHours?['open_now'] ?? regularOpeningHours?['open_now'])
              as bool?,
      status: result['business_status']?.toString(),
    );
  }

  Future<String?> fetchBusinessStatus(String placeId) async {
    final apiKey = await PlatformConfigService.getMapsApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Maps API key is not available on this device.');
    }

    final result = await _fetchPlaceResult(
      placeId,
      apiKey: apiKey,
      fields: 'business_status',
    );

    return result['business_status']?.toString();
  }

  Future<Map<String, dynamic>> _fetchPlaceResult(
    String placeId, {
    required String apiKey,
    required String fields,
    String? reviewsSort,
  }) async {
    final queryParameters = <String, String>{
      'place_id': placeId,
      'fields': fields,
      'key': apiKey,
    };

    if (reviewsSort != null && reviewsSort.isNotEmpty) {
      queryParameters['reviews_sort'] = reviewsSort;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      queryParameters,
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch Google Places details (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status']?.toString() ?? 'UNKNOWN_ERROR';
    if (status != 'OK') {
      final errorMessage = body['error_message']?.toString();
      throw Exception(errorMessage ?? 'Google Places returned $status.');
    }

    return body['result'] as Map<String, dynamic>? ?? {};
  }

  List<String> _toStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  String _formatReview(Map<String, dynamic> review) {
    final text = review['text']?.toString().trim() ?? '';
    if (text.isEmpty) {
      return '';
    }

    final author = review['author_name']?.toString().trim();
    final rating = review['rating']?.toString();
    final time = review['relative_time_description']?.toString().trim();
    final summaryParts = <String>[
      if (author != null && author.isNotEmpty) author,
      if (rating != null && rating.isNotEmpty) '$rating/5',
      if (time != null && time.isNotEmpty) time,
    ];
    final summary = summaryParts.join(' - ');

    if (summary.isEmpty) {
      return text;
    }

    return '$summary\n$text';
  }

  String _prefer(String? candidate, String fallback) {
    if (candidate == null || candidate.trim().isEmpty) {
      return fallback;
    }
    return candidate;
  }

  String? _displayStatus(String? status, bool? isOpen) {
    if (isOpen == true) {
      return 'Open now';
    }

    if (isOpen == false) {
      return 'Closed now';
    }

    if (status == null || status.trim().isEmpty) {
      return null;
    }

    switch (status.toUpperCase()) {
      case 'OPERATIONAL':
        return 'Operational';
      case 'CLOSED_TEMPORARILY':
        return 'Temporarily closed';
      case 'CLOSED_PERMANENTLY':
        return 'Permanently closed';
      default:
        return status;
    }
  }
}
