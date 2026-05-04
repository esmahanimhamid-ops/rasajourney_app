import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class RestaurantImportResult {
  final int sourceRows;
  final int importedRestaurants;
  final int skippedRows;

  const RestaurantImportResult({
    required this.sourceRows,
    required this.importedRestaurants,
    required this.skippedRows,
  });
}

class RestaurantImportService {
  RestaurantImportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<RestaurantImportResult> importFromAsset({
    String assetPath = 'assets/data/restaurants.csv',
  }) async {
    final csvString = await rootBundle.loadString(assetPath);
    final rows = csv.decodeWithHeaders(csvString);
    final groupedRestaurants = <String, _RestaurantAggregate>{};
    var skippedRows = 0;

    for (final row in rows) {
      final name = _readValue(row, const [
        'place_name',
        'restaurant name',
        'restaurant_name',
        'restaurant',
        'name',
      ]);
      final placeId = _readValue(row, const [
        'place_id',
        'placeid',
      ]);
      final address = _readValue(row, const [
        'location',
        'address',
        'vicinity',
        'formatted_address',
      ]);
      final review = _readValue(row, const [
        'review_text',
        'review',
        'reviews',
        'text',
      ]);
      final status = _readValue(row, const [
        'status',
        'business_status',
      ]);
      final openNow = _readValue(row, const [
        'is_open',
        'open_now',
      ]);
      final operatingHours = _readValue(row, const [
        'operating_hours',
        'opening_hours',
        'hours',
      ]);
      final rating = _tryParseDouble(
        _readValue(row, const ['rating', 'ratings', 'stars']),
      );
      final lat = _tryParseDouble(
        _readValue(row, const ['latitude', 'lat']),
      );
      final lng = _tryParseDouble(
        _readValue(row, const ['longitude', 'langitude', 'lng', 'lon', 'long']),
      );

      if (name == null || name.isEmpty || lat == null || lng == null) {
        skippedRows++;
        continue;
      }

      final key = _buildDocumentId(name, lat, lng);
      final aggregate = groupedRestaurants.putIfAbsent(
        key,
        () => _RestaurantAggregate(
          placeId: placeId,
          name: name,
          address: address ?? '',
          lat: lat,
          lng: lng,
          status: status,
          openNow: _tryParseBool(openNow),
          operatingHours: _parseHours(operatingHours),
        ),
      );

      aggregate.addRow(
        placeId: placeId,
        address: address,
        review: review,
        rating: rating,
        status: status,
        openNow: _tryParseBool(openNow),
        operatingHours: _parseHours(operatingHours),
      );
    }

    WriteBatch batch = _firestore.batch();
    var operationsInBatch = 0;

    for (final entry in groupedRestaurants.entries) {
      final restaurant = entry.value;
      final docRef = _firestore.collection('restaurants').doc(entry.key);

      batch.set(docRef, {
        'placeId': restaurant.placeId,
        'name': restaurant.name,
        'address': restaurant.address,
        'locationText': restaurant.address,
        'lat': restaurant.lat,
        'lng': restaurant.lng,
        'location': GeoPoint(restaurant.lat, restaurant.lng),
        'rating': restaurant.averageRating,
        'ratingCount': restaurant.ratingCount,
        'reviews': restaurant.reviews,
        'status': restaurant.status,
        'isOpen': restaurant.openNow,
        'operatingHours': restaurant.operatingHours,
        'source': 'kaggle_csv',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      operationsInBatch++;

      if (operationsInBatch == 400) {
        await batch.commit();
        batch = _firestore.batch();
        operationsInBatch = 0;
      }
    }

    if (operationsInBatch > 0) {
      await batch.commit();
    }

    return RestaurantImportResult(
      sourceRows: rows.length,
      importedRestaurants: groupedRestaurants.length,
      skippedRows: skippedRows,
    );
  }

  String? _readValue(dynamic row, List<String> candidateHeaders) {
    for (final header in row.headerMap.keys) {
      final normalizedHeader = header.toString().trim().toLowerCase();
      if (candidateHeaders.contains(normalizedHeader)) {
        final value = row[header]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  double? _tryParseDouble(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return double.tryParse(value);
  }

  bool? _tryParseBool(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == 'open' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == 'closed' || normalized == 'no') {
      return false;
    }

    return null;
  }

  List<String> _parseHours(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const [];
    }

    return value
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _buildDocumentId(String name, double lat, double lng) {
    final normalizedName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final latKey = lat.toStringAsFixed(5).replaceAll('.', '_');
    final lngKey = lng.toStringAsFixed(5).replaceAll('.', '_');
    return '$normalizedName-$latKey-$lngKey';
  }
}

class _RestaurantAggregate {
  _RestaurantAggregate({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    required this.openNow,
    required this.operatingHours,
  });

  String? placeId;
  final String name;
  String address;
  final double lat;
  final double lng;
  String? status;
  bool? openNow;
  final List<String> operatingHours;
  final List<double> _ratings = [];
  final List<String> _reviews = [];

  void addRow({
    String? placeId,
    String? address,
    String? review,
    double? rating,
    String? status,
    bool? openNow,
    List<String>? operatingHours,
  }) {
    if ((this.placeId == null || this.placeId!.isEmpty) &&
        placeId != null &&
        placeId.isNotEmpty) {
      this.placeId = placeId;
    }

    if ((this.address.isEmpty) && address != null && address.isNotEmpty) {
      this.address = address;
    }

    if ((this.status == null || this.status!.isEmpty) &&
        status != null &&
        status.isNotEmpty) {
      this.status = status;
    }

    if (this.openNow == null && openNow != null) {
      this.openNow = openNow;
    }

    if (this.operatingHours.isEmpty &&
        operatingHours != null &&
        operatingHours.isNotEmpty) {
      this.operatingHours.addAll(operatingHours);
    }

    if (rating != null) {
      _ratings.add(rating);
    }

    if (review != null && review.isNotEmpty && !_reviews.contains(review)) {
      _reviews.add(review);
    }
  }

  double get averageRating {
    if (_ratings.isEmpty) {
      return 0;
    }

    final total = _ratings.reduce((sum, value) => sum + value);
    return double.parse((total / _ratings.length).toStringAsFixed(1));
  }

  int get ratingCount => _ratings.length;

  List<String> get reviews => _reviews.take(5).toList();
}
