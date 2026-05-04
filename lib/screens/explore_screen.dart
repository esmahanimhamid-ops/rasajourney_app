import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/restaurant.dart';
import '../services/restaurant_cleanup_service.dart';
import 'restaurant_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Restaurant? selectedRestaurant;
  bool _isCleaningClosedRestaurants = false;

  static const LatLng _perlisCenter = LatLng(6.4449, 100.2048);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return restaurants;
    }

    return restaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(query) ||
          restaurant.address.toLowerCase().contains(query);
    }).toList();
  }

  Set<Marker> _buildMarkers(List<Restaurant> restaurants) {
    return restaurants
        .map(
          (restaurant) => Marker(
            markerId: MarkerId(restaurant.name),
            position: LatLng(restaurant.lat, restaurant.lng),
            infoWindow: InfoWindow(title: restaurant.name),
            onTap: () {
              setState(() {
                selectedRestaurant = restaurant;
              });
            },
          ),
        )
        .toSet();
  }

  void _openRestaurantDetails(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(
          restaurant: restaurant,
        ),
      ),
    );
  }

  Future<void> _deletePermanentlyClosedRestaurants() async {
    final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Permanently Closed Restaurants?'),
              content: const Text(
                'This will check restaurants with a place ID and delete only those marked permanently closed by Google Places.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldContinue || !mounted) {
      return;
    }

    setState(() {
      _isCleaningClosedRestaurants = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Checking Google Places and deleting permanently closed restaurants...',
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final result = await RestaurantCleanupService()
          .deletePermanentlyClosedRestaurants();

      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();

      final deletedPreview = result.deletedNames.take(8).join('\n');
      final deletedMoreCount = result.deletedNames.length - result.deletedNames.take(8).length;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Cleanup Complete'),
            content: SingleChildScrollView(
              child: Text(
                [
                  'Checked: ${result.checkedCount}',
                  'Skipped without placeId: ${result.skippedCount}',
                  'Deleted permanently closed: ${result.deletedCount}',
                  'Errors: ${result.errors.length}',
                  if (deletedPreview.isNotEmpty) '',
                  if (deletedPreview.isNotEmpty) 'Deleted restaurants:',
                  if (deletedPreview.isNotEmpty) deletedPreview,
                  if (deletedMoreCount > 0) '...and $deletedMoreCount more',
                ].join('\n'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleanup failed: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCleaningClosedRestaurants = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Food in Perlis'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Delete permanently closed restaurants',
              onPressed: _isCleaningClosedRestaurants
                  ? null
                  : _deletePermanentlyClosedRestaurants,
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load restaurants.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final restaurants = snapshot.data!.docs
              .map((doc) => Restaurant.fromMap(doc.data(), id: doc.id))
              .where((restaurant) => restaurant.name.isNotEmpty)
              .toList();
          final filteredRestaurants = _filterRestaurants(restaurants);
          final markers = _buildMarkers(filteredRestaurants);

          if (selectedRestaurant != null &&
              !filteredRestaurants.any(
                (restaurant) => restaurant.name == selectedRestaurant!.name,
              )) {
            selectedRestaurant = null;
          }

          if (filteredRestaurants.isEmpty) {
            return const Center(
              child: Text('No restaurants found.'),
            );
          }

          return Column(
            children: [
              SizedBox(
                height: 260,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedRestaurant != null
                        ? LatLng(selectedRestaurant!.lat, selectedRestaurant!.lng)
                        : _perlisCenter,
                    zoom: selectedRestaurant != null ? 16 : 13,
                  ),
                  markers: markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
              ),
              if (selectedRestaurant != null)
                Container(
                  width: double.infinity,
                  color: Colors.deepOrange.shade50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    'Selected: ${selectedRestaurant!.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredRestaurants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final restaurant = filteredRestaurants[index];

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.restaurant),
                        ),
                        title: Text(restaurant.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(restaurant.address),
                            const SizedBox(height: 4),
                            Text(
                              restaurant.rating > 0
                                  ? 'Rating ${restaurant.rating.toStringAsFixed(1)} (${restaurant.ratingCount})'
                                  : restaurant.status,
                              style: TextStyle(
                                color: Colors.deepOrange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            selectedRestaurant = restaurant;
                          });
                          _openRestaurantDetails(restaurant);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 18),
                          onPressed: () {
                            _openRestaurantDetails(restaurant);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
