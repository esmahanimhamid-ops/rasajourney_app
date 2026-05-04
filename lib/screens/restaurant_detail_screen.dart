import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';
import '../services/google_places_service.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late Restaurant _restaurant;
  bool _isLoadingDetails = false;
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.restaurant;
    _loadPlaceDetailsIfNeeded();
  }

  Future<void> _loadPlaceDetailsIfNeeded() async {
    if (!_shouldFetchPlaceDetails(_restaurant)) {
      return;
    }

    setState(() {
      _isLoadingDetails = true;
      _detailsError = null;
    });

    try {
      final enrichedRestaurant = await GooglePlacesService().enrichRestaurant(
        _restaurant,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _restaurant = enrichedRestaurant;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _detailsError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  bool _shouldFetchPlaceDetails(Restaurant restaurant) {
    final placeId = restaurant.placeId;
    if (placeId == null || placeId.isEmpty) {
      return false;
    }

    return restaurant.operatingHours.isEmpty ||
        restaurant.reviews.isEmpty ||
        restaurant.isOpen == null ||
        restaurant.ratingCount == 0 ||
        restaurant.image.isEmpty ||
        restaurant.address == 'Location unavailable' ||
        restaurant.status == 'Status unavailable';
  }

  void openMap(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not open map';
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant;
    final statusColor = restaurant.isOpen == true
        ? Colors.green
        : restaurant.isOpen == false
            ? Colors.red
            : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingDetails) const LinearProgressIndicator(),
            if (restaurant.image.isNotEmpty)
              Image.network(
                restaurant.image,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _DetailHero(
                    restaurant: restaurant,
                  );
                },
              )
            else
              _DetailHero(
                restaurant: restaurant,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                restaurant.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      restaurant.address,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoChip(
                    icon: Icons.schedule,
                    label: restaurant.status,
                    color: statusColor,
                  ),
                  _InfoChip(
                    icon: Icons.star,
                    label: restaurant.rating > 0
                        ? '${restaurant.rating.toStringAsFixed(1)} / 5'
                        : 'No rating yet',
                    color: Colors.amber.shade700,
                  ),
                  _InfoChip(
                    icon: Icons.reviews,
                    label: '${restaurant.ratingCount} ratings',
                    color: Colors.deepOrange,
                  ),
                ],
              ),
            ),
            if (_detailsError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Could not refresh live place details. Showing saved data.\n$_detailsError',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ),
            if (restaurant.placeId != null && restaurant.placeId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Live details are synced from Google Places using place ID.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SectionCard(
                title: 'Operating Hours',
                icon: Icons.access_time,
                child: restaurant.operatingHours.isEmpty
                    ? const Text('Operating hours are not available yet.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: restaurant.operatingHours
                            .map(
                              (hours) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(hours),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SectionCard(
                title: 'Customer Reviews',
                icon: Icons.chat_bubble_outline,
                child: restaurant.reviews.isEmpty
                    ? const Text('No reviews available yet.')
                    : Column(
                        children: restaurant.reviews
                            .take(3)
                            .map(
                              (review) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(review),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
            Container(
              height: 220,
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(restaurant.lat, restaurant.lng),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('restaurant'),
                    position: LatLng(restaurant.lat, restaurant.lng),
                    infoWindow: InfoWindow(title: restaurant.name),
                  ),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    openMap(restaurant.lat, restaurant.lng);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Open in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.restaurant,
  });

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFA726),
            Color(0xFFD84315),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            restaurant.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
