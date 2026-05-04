import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String name;
  final String address;
  final String image;
  final double lat;
  final double lng;

  Restaurant({
    required this.name,
    required this.address,
    required this.image,
    required this.lat,
    required this.lng,
  });

  factory Restaurant.fromMap(Map<String, dynamic> data) {
    final geoPoint = data['location'] as GeoPoint?;
    final latValue = data['lat'] ?? geoPoint?.latitude ?? 0.0;
    final lngValue = data['lng'] ?? geoPoint?.longitude ?? 0.0;

    return Restaurant(
      name: (data['name'] ?? '').toString(),
      address: (data['address'] ?? data['vicinity'] ?? '').toString(),
      image: (data['image'] ?? data['imageUrl'] ?? 'https://via.placeholder.com/600x400').toString(),
      lat: (latValue as num).toDouble(),
      lng: (lngValue as num).toDouble(),
    );
  }
}
