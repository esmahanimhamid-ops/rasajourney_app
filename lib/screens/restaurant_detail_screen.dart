import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';
import '../services/google_places_service.dart';
import '../theme/app_theme.dart';

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
  int _galleryIndex = 0;
  bool _showGalleryHint = true;

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
        restaurant.galleryImages.isEmpty ||
        restaurant.address == 'Location unavailable' ||
        restaurant.status == 'Status unavailable';
  }

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return;
    }

    throw 'Could not open map';
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant;
    final statusForeground = restaurant.isOpen == true
        ? const Color(0xFF2F7A4A)
        : restaurant.isOpen == false
            ? const Color(0xFF9D3243)
            : AppTheme.mutedBrown;
    final statusBackground = restaurant.isOpen == true
        ? const Color(0xFFE8F7EE)
        : restaurant.isOpen == false
            ? const Color(0xFFFFEAEF)
            : const Color(0xFFFFF5E9);
    final halalForeground = restaurant.halalStatus == 'Halal'
        ? const Color(0xFF2F7A4A)
        : restaurant.halalStatus == 'Non-halal'
            ? const Color(0xFF9D3243)
            : AppTheme.mutedBrown;
    final halalBackground = restaurant.halalStatus == 'Halal'
        ? const Color(0xFFE8F7EE)
        : restaurant.halalStatus == 'Non-halal'
            ? const Color(0xFFFFEAEF)
            : const Color(0xFFFFF5E9);
    final galleryImages = restaurant.galleryImages;

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.cream,
              AppTheme.warmWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingDetails) const LinearProgressIndicator(),
                    _PhotoGalleryHeader(
                      restaurant: restaurant,
                      galleryImages: galleryImages,
                      currentIndex: _galleryIndex,
                      showSwipeHint:
                          _showGalleryHint && galleryImages.length > 1,
                      onSwipeDetected: () {
                        if (!_showGalleryHint) {
                          return;
                        }

                        setState(() {
                          _showGalleryHint = false;
                        });
                      },
                      onPageChanged: (index) {
                        setState(() {
                          _galleryIndex = index;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.cocoa,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppTheme.mutedBrown,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              restaurant.address,
                              style: const TextStyle(
                                color: AppTheme.mutedBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoChip(
                            icon: Icons.restaurant_menu_rounded,
                            label: restaurant.restaurantType,
                            backgroundColor: AppTheme.blush,
                            foregroundColor: AppTheme.clay,
                          ),
                          _InfoChip(
                            icon: restaurant.halalStatus == 'Non-halal'
                                ? Icons.no_food_rounded
                                : Icons.verified_outlined,
                            label: restaurant.halalStatus,
                            backgroundColor: halalBackground,
                            foregroundColor: halalForeground,
                          ),
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label: restaurant.status,
                            backgroundColor: statusBackground,
                            foregroundColor: statusForeground,
                          ),
                          _InfoChip(
                            icon: Icons.star_rounded,
                            label: restaurant.rating > 0
                                ? '${restaurant.rating.toStringAsFixed(1)} / 5'
                                : 'No rating yet',
                            backgroundColor: const Color(0xFFFFF2D9),
                            foregroundColor: const Color(0xFF9A6504),
                          ),
                          _InfoChip(
                            icon: Icons.reviews_outlined,
                            label: '${restaurant.ratingCount} ratings',
                            backgroundColor: const Color(0xFFFFF3EA),
                            foregroundColor: AppTheme.clay,
                          ),
                        ],
                      ),
                    ),
                    if (_detailsError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _NoticeCard(
                          text:
                              'Could not refresh live place details. Showing saved data.\n$_detailsError',
                          foregroundColor: const Color(0xFF8A5A0E),
                          backgroundColor: const Color(0xFFFFF3E0),
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _SectionCard(
                        title: 'Menu Highlights',
                        subtitle:
                            'Popular dishes based on available data and customer mentions.',
                        icon: Icons.ramen_dining_outlined,
                        child: restaurant.menuItems.isEmpty
                            ? const Text(
                                'Menu details are not available yet for this restaurant.',
                              )
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: restaurant.menuItems
                                    .map(
                                      (item) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF5EA),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            color: AppTheme.cocoa,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _SectionCard(
                        title: 'Operating Hours',
                        subtitle:
                            'Check whether the restaurant fits your next visit plan.',
                        icon: Icons.access_time_rounded,
                        child: restaurant.operatingHours.isEmpty
                            ? const Text('Operating hours are not available yet.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: restaurant.operatingHours
                                    .map(
                                      (hours) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
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
                        subtitle:
                            'A quick read before you decide what to order.',
                        icon: Icons.chat_bubble_outline_rounded,
                        child: restaurant.reviews.isEmpty
                            ? const Text('No reviews available yet.')
                            : Column(
                                children: restaurant.reviews
                                    .take(4)
                                    .map(
                                      (review) => Container(
                                        width: double.infinity,
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF8F2),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: Text(
                                          review,
                                          style: TextStyle(
                                            color: Colors.brown.shade600,
                                            height: 1.55,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _SectionCard(
                        title: 'Find The Place',
                        subtitle:
                            'Use the map preview first, then open directions when you are ready to go.',
                        icon: Icons.map_outlined,
                        child: Column(
                          children: [
                            Container(
                              height: 220,
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
                                    position: LatLng(
                                      restaurant.lat,
                                      restaurant.lng,
                                    ),
                                    infoWindow:
                                        InfoWindow(title: restaurant.name),
                                  ),
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  _openMap(restaurant.lat, restaurant.lng);
                                },
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Open in Google Maps'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoGalleryHeader extends StatelessWidget {
  const _PhotoGalleryHeader({
    required this.restaurant,
    required this.galleryImages,
    required this.currentIndex,
    required this.showSwipeHint,
    required this.onSwipeDetected,
    required this.onPageChanged,
  });

  final Restaurant restaurant;
  final List<String> galleryImages;
  final int currentIndex;
  final bool showSwipeHint;
  final VoidCallback onSwipeDetected;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (galleryImages.isEmpty) {
      return _DetailHero(restaurant: restaurant);
    }

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              if (showSwipeHint &&
                  notification.metrics.axis == Axis.horizontal &&
                  (notification.scrollDelta?.abs() ?? 0) > 0) {
                onSwipeDetected();
              }
              return false;
            },
            child: PageView.builder(
              itemCount: galleryImages.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: galleryImages[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFFFE5D6),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppTheme.clay,
                    ),
                  ),
                  errorWidget: (_, __, ___) => _DetailHero(
                    restaurant: restaurant,
                  ),
                );
              },
            ),
          ),
          if (showSwipeHint)
            Positioned(
              left: 16,
              right: 16,
              bottom: 42,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Swipe through restaurant and signature-dish photos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: List.generate(
                      galleryImages.length,
                      (index) => Container(
                        margin: EdgeInsets.only(
                          right: index == galleryImages.length - 1 ? 0 : 6,
                        ),
                        width: currentIndex == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      height: 280,
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
            Icons.restaurant_menu_rounded,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            restaurant.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
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
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
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
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppTheme.blush,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.clay),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.cocoa,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.brown.shade400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String text;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: foregroundColor),
      ),
    );
  }
}
