import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String? placeId;
  final String name;
  final String address;
  final String image;
  final double lat;
  final double lng;
  final double rating;
  final int ratingCount;
  final List<String> reviews;
  final List<String> operatingHours;
  final bool? isOpen;
  final String status;

  Restaurant({
    required this.id,
    required this.placeId,
    required this.name,
    required this.address,
    required this.image,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.ratingCount,
    required this.reviews,
    required this.operatingHours,
    required this.isOpen,
    required this.status,
  });

  factory Restaurant.fromMap(
    Map<String, dynamic> data, {
    String id = '',
  }) {
    final geoPoint = data['location'] as GeoPoint?;
    final latValue = data['lat'] ?? geoPoint?.latitude ?? 0.0;
    final lngValue = data['lng'] ?? geoPoint?.longitude ?? 0.0;
    final addressValue =
        data['address'] ??
            data['locationText'] ??
            data['vicinity'] ??
            'Location unavailable';
    final isOpenValue = _parseIsOpen(data);

    return Restaurant(
      id: id,
      placeId: data['placeId']?.toString(),
      name: (data['name'] ?? '').toString(),
      address: addressValue.toString(),
      image: (data['image'] ?? data['imageUrl'] ?? '').toString(),
      lat: (latValue as num).toDouble(),
      lng: (lngValue as num).toDouble(),
      rating: _toDouble(data['rating']),
      ratingCount: _toInt(data['ratingCount']),
      reviews: _toStringList(data['reviews']),
      operatingHours: _toStringList(
        data['operatingHours'] ?? data['openingHours'] ?? data['hours'],
      ),
      isOpen: isOpenValue,
      status: _parseStatus(data, isOpenValue),
    );
  }

  Restaurant copyWith({
    String? id,
    String? placeId,
    String? name,
    String? address,
    String? image,
    double? lat,
    double? lng,
    double? rating,
    int? ratingCount,
    List<String>? reviews,
    List<String>? operatingHours,
    bool? isOpen,
    String? status,
  }) {
    return Restaurant(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      image: image ?? this.image,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      reviews: reviews ?? this.reviews,
      operatingHours: operatingHours ?? this.operatingHours,
      isOpen: isOpen ?? this.isOpen,
      status: status ?? this.status,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return const [];
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static bool? _parseIsOpen(Map<String, dynamic> data) {
    final value = data['isOpen'] ?? data['openNow'];

    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'open' || normalized == 'true') {
        return true;
      }
      if (normalized == 'closed' || normalized == 'false') {
        return false;
      }
    }

    return null;
  }

  static String _parseStatus(Map<String, dynamic> data, bool? isOpen) {
    final rawStatus = data['status'] ?? data['businessStatus'];
    if (rawStatus is String && rawStatus.trim().isNotEmpty) {
      return _humanizeStatus(rawStatus.trim());
    }

    if (isOpen == true) {
      return 'Open now';
    }

    if (isOpen == false) {
      return 'Closed now';
    }

    return 'Status unavailable';
  }

  static String _humanizeStatus(String value) {
    final normalized = value.trim();

    switch (normalized.toUpperCase()) {
      case 'OPERATIONAL':
        return 'Operational';
      case 'CLOSED_TEMPORARILY':
        return 'Temporarily closed';
      case 'CLOSED_PERMANENTLY':
        return 'Permanently closed';
      case 'OPEN':
        return 'Open now';
      case 'CLOSED':
        return 'Closed now';
      default:
        return normalized
            .toLowerCase()
            .split('_')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }
}
