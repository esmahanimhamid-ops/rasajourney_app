import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/restaurant.dart';
import '../screens/auth_screen.dart';
import '../services/auth_service.dart';
import '../services/restaurant_cleanup_service.dart';
import '../services/user_content_service.dart';
import '../theme/app_theme.dart';
import 'restaurant_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserContentService _userContentService = UserContentService();

  Restaurant? selectedRestaurant;
  bool _isCleaningClosedRestaurants = false;
  bool _nearMeOnly = false;
  bool _isLocatingUser = false;
  LatLng? _userLocation;
  String? _selectedTypeFilter;
  String? _selectedAreaFilter;

  static const LatLng _perlisCenter = LatLng(6.4449, 100.2048);
  static const double _nearMeRadiusKm = 10;

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
    final filtered = restaurants.where((restaurant) {
      final matchesQuery = query.isEmpty ||
          restaurant.name.toLowerCase().contains(query) ||
          restaurant.address.toLowerCase().contains(query) ||
          restaurant.restaurantType.toLowerCase().contains(query) ||
          _extractAreaLabel(restaurant.address).toLowerCase().contains(query);

      final matchesType = _selectedTypeFilter == null ||
          restaurant.restaurantType == _selectedTypeFilter;
      final matchesArea = _selectedAreaFilter == null ||
          _extractAreaLabel(restaurant.address) == _selectedAreaFilter;

      final matchesNearMe = !_nearMeOnly ||
          (_userLocation != null &&
              _distanceKm(
                    _userLocation!,
                    LatLng(restaurant.lat, restaurant.lng),
                  ) <=
                  _nearMeRadiusKm);

      return matchesQuery && matchesType && matchesArea && matchesNearMe;
    }).toList();

    if (_nearMeOnly && _userLocation != null) {
      filtered.sort(
        (a, b) => _distanceKm(
          _userLocation!,
          LatLng(a.lat, a.lng),
        ).compareTo(
          _distanceKm(
            _userLocation!,
            LatLng(b.lat, b.lng),
          ),
        ),
      );
    }

    return filtered;
  }

  Set<Marker> _buildMarkers(List<Restaurant> restaurants) {
    final markers = restaurants
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

    if (_nearMeOnly && _userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  List<String> _availableTypes(List<Restaurant> restaurants) {
    final values = restaurants
        .map((restaurant) => restaurant.restaurantType.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<String> _availableAreas(List<Restaurant> restaurants) {
    final values = restaurants
        .map((restaurant) => _extractAreaLabel(restaurant.address))
        .where((value) => value != 'Area unavailable')
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  Future<void> _showFilterSheet(List<Restaurant> restaurants) async {
    final result = await showModalBottomSheet<_FilterDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterSheet(
          availableTypes: _availableTypes(restaurants),
          availableAreas: _availableAreas(restaurants),
          initialType: _selectedTypeFilter,
          initialArea: _selectedAreaFilter,
          initialNearMeOnly: _nearMeOnly,
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedTypeFilter = result.type;
      _selectedAreaFilter = result.area;
    });

    if (result.nearMeOnly != _nearMeOnly) {
      await _setNearMeMode(result.nearMeOnly);
    }
  }

  Future<void> _setNearMeMode(bool enabled) async {
    if (!enabled) {
      if (!mounted) {
        return;
      }

      setState(() {
        _nearMeOnly = false;
      });
      return;
    }

    setState(() {
      _isLocatingUser = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Please turn on location services to use the Near Me filter.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Please enable it in app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _nearMeOnly = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Showing restaurants within 10 km of your location.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _nearMeOnly = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingUser = false;
        });
      }
    }
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

  Future<User?> _requireSignedInUser({
    required String actionLabel,
    required String actionDescription,
    required IconData icon,
  }) async {
    final existingUser = AuthService.currentUser;
    if (existingUser != null) {
      await AuthService.syncUserProfile(existingUser);
      return existingUser;
    }

    final shouldOpenAuth = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LoginRequiredSheet(
          actionLabel: actionLabel,
          actionDescription: actionDescription,
          icon: icon,
        );
      },
    );

    if (shouldOpenAuth != true) {
      return null;
    }

    final user = await AuthScreen.open(context);
    if (user != null) {
      await AuthService.syncUserProfile(user);
    }
    return user;
  }

  Future<void> _handleAccountAction(String action) async {
    switch (action) {
      case 'login':
        await AuthScreen.open(context);
        break;
      case 'logout':
        await AuthService.signOut();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully.')),
        );
        break;
    }
  }

  Future<void> _toggleFavourite(Restaurant restaurant) async {
    final user = await _requireSignedInUser(
      actionLabel: 'Save to journal',
      actionDescription:
          'You need to login or sign up first before saving ${restaurant.name} to your favourites.',
      icon: Icons.favorite_rounded,
    );
    if (user == null) {
      return;
    }

    try {
      final isSaved = await _userContentService.toggleFavourite(
        user: user,
        restaurant: restaurant,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved
                ? '${restaurant.name} saved to your journal.'
                : '${restaurant.name} removed from your journal.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update favourite: $error'),
        ),
      );
    }
  }

  Future<void> _showReviewDialog(Restaurant restaurant) async {
    final user = await _requireSignedInUser(
      actionLabel: 'Write a review',
      actionDescription:
          'You need to login or sign up first before sharing your review for ${restaurant.name}.',
      icon: Icons.rate_review_rounded,
    );
    if (user == null) {
      return;
    }

    final reviewDraft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (dialogContext) {
        final reviewController = TextEditingController();
        double rating = 4;
        double deliciousScale = 4;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.warmWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Text('Review ${restaurant.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Star rating',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Wrap(
                        spacing: 4,
                        children: List.generate(
                          5,
                          (index) => IconButton(
                            onPressed: () {
                              setDialogState(() {
                                rating = index + 1.0;
                              });
                            },
                            icon: Icon(
                              index < rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFF2A31D),
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text(
                          'Delicious scale',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '${deliciousScale.toInt()}/5 - ${_deliciousScaleLabel(deliciousScale)}',
                          style: const TextStyle(
                            color: AppTheme.clay,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: deliciousScale,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: AppTheme.clay,
                      inactiveColor: AppTheme.sand,
                      label:
                          '${deliciousScale.toInt()} - ${_deliciousScaleLabel(deliciousScale)}',
                      onChanged: (value) {
                        setDialogState(() {
                          deliciousScale = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText:
                            'Describe the taste, vibe, or what you would order again...',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = reviewController.text.trim();
                    if (text.isEmpty) {
                      setDialogState(() {
                        errorText =
                            'Please write a short review before submitting.';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _ReviewDraft(
                        rating: rating,
                        deliciousScale: deliciousScale,
                        text: text,
                      ),
                    );
                  },
                  child: const Text('Save Review'),
                ),
              ],
            );
          },
        );
      },
    );

    if (reviewDraft == null) {
      return;
    }

    try {
      await _userContentService.submitReview(
        user: user,
        restaurant: restaurant,
        rating: reviewDraft.rating,
        deliciousScale: reviewDraft.deliciousScale,
        text: reviewDraft.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review saved for ${restaurant.name}.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save review: $error'),
        ),
      );
    }
  }

  Future<void> _deletePermanentlyClosedRestaurants() async {
    final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Text('Delete Permanently Closed Restaurants?'),
              content: const Text(
                'This will check restaurants with a place ID and delete only those marked permanently closed by Google Places.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
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
      final deletedMoreCount =
          result.deletedNames.length - result.deletedNames.take(8).length;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
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

  String _buildRatingSummary(Restaurant restaurant) {
    if (restaurant.rating > 0) {
      return '${restaurant.rating.toStringAsFixed(1)} (${restaurant.ratingCount})';
    }
    return 'No rating yet';
  }

  String _extractAreaLabel(String address) {
    if (address.trim().isEmpty || address == 'Location unavailable') {
      return 'Area unavailable';
    }

    final normalized = address.toLowerCase();
    const knownAreas = {
      'kuala perlis': 'Kuala Perlis',
      'kangar': 'Kangar',
      'arau': 'Arau',
      'padang besar': 'Padang Besar',
      'beseri': 'Beseri',
      'sangar': 'Sangar',
      'simpang empat': 'Simpang Empat',
      'tambun tulang': 'Tambun Tulang',
      'mata ayer': 'Mata Ayer',
      'kaki bukit': 'Kaki Bukit',
      'jejawi': 'Jejawi',
    };

    for (final entry in knownAreas.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    final segments = address
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    for (final rawSegment in segments.reversed) {
      final cleaned = rawSegment
          .replaceAll(RegExp(r'\b\d{5}\b'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final lowered = cleaned.toLowerCase();

      if (cleaned.isEmpty ||
          lowered == 'malaysia' ||
          lowered == 'perlis' ||
          lowered.contains('malaysia')) {
        continue;
      }

      return cleaned;
    }

    return 'Area unavailable';
  }

  double _distanceKm(LatLng from, LatLng to) {
    final distanceMeters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return distanceMeters / 1000;
  }

  String _distanceLabel(Restaurant restaurant) {
    if (!_nearMeOnly || _userLocation == null) {
      return '';
    }

    final km = _distanceKm(
      _userLocation!,
      LatLng(restaurant.lat, restaurant.lng),
    );

    if (km < 1) {
      return '${(km * 1000).round()} m away';
    }

    return '${km.toStringAsFixed(1)} km away';
  }

  List<_ActiveFilterChipData> _activeFilterChips() {
    final chips = <_ActiveFilterChipData>[];

    if (_selectedTypeFilter != null) {
      chips.add(
        _ActiveFilterChipData(
          label: _selectedTypeFilter!,
          onRemoved: () {
            setState(() {
              _selectedTypeFilter = null;
            });
          },
        ),
      );
    }

    if (_selectedAreaFilter != null) {
      chips.add(
        _ActiveFilterChipData(
          label: _selectedAreaFilter!,
          onRemoved: () {
            setState(() {
              _selectedAreaFilter = null;
            });
          },
        ),
      );
    }

    if (_nearMeOnly) {
      chips.add(
        _ActiveFilterChipData(
          label: 'Within ${_nearMeRadiusKm.toInt()} km',
          onRemoved: () {
            _setNearMeMode(false);
          },
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Taste Perlis'),
            SizedBox(height: 2),
            Text(
              'Find restaurants worth remembering',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedBrown,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<User?>(
            stream: AuthService.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data ?? AuthService.currentUser;

              return PopupMenuButton<String>(
                tooltip: user == null ? 'Login or sign up' : user.email,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onSelected: _handleAccountAction,
                itemBuilder: (context) {
                  if (user == null) {
                    return const [
                      PopupMenuItem(
                        value: 'login',
                        child: Text('Login / Sign Up'),
                      ),
                    ];
                  }

                  return [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(user.email ?? 'Signed in'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ];
                },
                icon: const Icon(Icons.account_circle_outlined),
              );
            },
          ),
          if (kDebugMode)
            IconButton(
              tooltip: 'Delete permanently closed restaurants',
              onPressed: _isCleaningClosedRestaurants
                  ? null
                  : _deletePermanentlyClosedRestaurants,
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _ExploreStateMessage(
                title: 'Something interrupted the food trail.',
                subtitle: 'We could not load restaurants right now.',
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
            final activeFilterChips = _activeFilterChips();

            if (selectedRestaurant != null &&
                !filteredRestaurants.any(
                  (restaurant) => restaurant.name == selectedRestaurant!.name,
                )) {
              selectedRestaurant = null;
            }

            return StreamBuilder<User?>(
              stream: AuthService.authStateChanges(),
              builder: (context, authSnapshot) {
                final user = authSnapshot.data ?? AuthService.currentUser;

                return StreamBuilder<Set<String>>(
                  stream: _userContentService.favouriteIdsStream(user?.uid),
                  initialData: const <String>{},
                  builder: (context, favouritesSnapshot) {
                    final favouriteIds =
                        favouritesSnapshot.data ?? const <String>{};
                    final hasResults = filteredRestaurants.isNotEmpty;

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _ExploreHeroPanel(
                              restaurantCount: filteredRestaurants.length,
                              selectedRestaurant: selectedRestaurant,
                              query: _searchController.text.trim(),
                              nearMeOnly: _nearMeOnly,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _SearchAndFilterCard(
                              controller: _searchController,
                              activeFilterChips: activeFilterChips,
                              isLocatingUser: _isLocatingUser,
                              nearMeOnly: _nearMeOnly,
                              onToggleNearMe: () {
                                _setNearMeMode(!_nearMeOnly);
                              },
                              onOpenFilters: () {
                                _showFilterSheet(restaurants);
                              },
                            ),
                          ),
                        ),
                        if (hasResults)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                0,
                              ),
                              child: _MapExperienceCard(
                                markers: markers,
                                selectedRestaurant: selectedRestaurant,
                                perlisCenter: _perlisCenter,
                                userLocation: _userLocation,
                                nearMeOnly: _nearMeOnly,
                              ),
                            ),
                          ),
                        if (hasResults)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                              child: Text(
                                'Places That Could Become A Favourite',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.cocoa,
                                ),
                              ),
                            ),
                          ),
                        if (hasResults)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final restaurant = filteredRestaurants[index];
                                  final isFavourite =
                                      favouriteIds.contains(restaurant.id);

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          index == filteredRestaurants.length - 1
                                              ? 0
                                              : 14,
                                    ),
                                    child: _ExploreRestaurantCard(
                                      restaurant: restaurant,
                                      ratingSummary: _buildRatingSummary(
                                        restaurant,
                                      ),
                                      distanceLabel: _distanceLabel(
                                        restaurant,
                                      ),
                                      areaLabel: _extractAreaLabel(
                                        restaurant.address,
                                      ),
                                      isFavourite: isFavourite,
                                      onOpen: () {
                                        setState(() {
                                          selectedRestaurant = restaurant;
                                        });
                                        _openRestaurantDetails(restaurant);
                                      },
                                      onSave:
                                          () => _toggleFavourite(restaurant),
                                      onReview:
                                          () => _showReviewDialog(restaurant),
                                    ),
                                  );
                                },
                                childCount: filteredRestaurants.length,
                              ),
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                24,
                                16,
                                24,
                              ),
                              child: _ExploreStateMessage(
                                title: 'No restaurants match that search yet.',
                                subtitle:
                                    _searchController.text.trim().isEmpty &&
                                            _selectedTypeFilter == null &&
                                            _selectedAreaFilter == null &&
                                            !_nearMeOnly
                                        ? 'Try again in a moment.'
                                        : 'Try another name, cuisine, area, or turn off Near Me.',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ExploreHeroPanel extends StatelessWidget {
  const _ExploreHeroPanel({
    required this.restaurantCount,
    required this.selectedRestaurant,
    required this.query,
    required this.nearMeOnly,
  });

  final int restaurantCount;
  final Restaurant? selectedRestaurant;
  final String query;
  final bool nearMeOnly;

  @override
  Widget build(BuildContext context) {
    final title = query.isEmpty
        ? nearMeOnly
            ? 'Nearby flavours are waiting.'
            : 'A warm food trail is waiting.'
        : 'Results for "$query"';
    final subtitle = selectedRestaurant == null
        ? 'Browse nearby restaurants, save the ones that feel special, and compare the taste notes before deciding where to go next.'
        : 'You are currently focused on ${selectedRestaurant!.name}. Open it to see dishes, menu hints, and the review details together.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD45720),
            Color(0xFFE56F21),
            Color(0xFFF0A43B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.restaurant_menu_rounded,
                label: '$restaurantCount places',
              ),
              const _HeroPill(
                icon: Icons.favorite_border_rounded,
                label: 'Save for later',
              ),
              _HeroPill(
                icon: Icons.near_me_outlined,
                label: nearMeOnly ? 'Near me on' : 'Filter by taste',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterCard extends StatelessWidget {
  const _SearchAndFilterCard({
    required this.controller,
    required this.activeFilterChips,
    required this.isLocatingUser,
    required this.nearMeOnly,
    required this.onToggleNearMe,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final List<_ActiveFilterChipData> activeFilterChips;
  final bool isLocatingUser;
  final bool nearMeOnly;
  final VoidCallback onToggleNearMe;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search by restaurant, area, or cuisine',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.trim().isEmpty
                  ? const Icon(Icons.local_dining_outlined)
                  : IconButton(
                      onPressed: controller.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.filter_list_rounded),
                label: const Text('Filter cuisine & area'),
              ),
              FilledButton.icon(
                onPressed: isLocatingUser ? null : onToggleNearMe,
                icon: isLocatingUser
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        nearMeOnly
                            ? Icons.my_location_rounded
                            : Icons.near_me_outlined,
                      ),
                label: Text(
                  isLocatingUser
                      ? 'Locating...'
                      : nearMeOnly
                          ? 'Near me active'
                          : 'Restaurants near me',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      nearMeOnly ? const Color(0xFFB5481E) : AppTheme.clay,
                ),
              ),
            ],
          ),
          if (activeFilterChips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeFilterChips
                    .map(
                      (chip) => InputChip(
                        label: Text(chip.label),
                        onDeleted: chip.onRemoved,
                        deleteIconColor: AppTheme.clay,
                        backgroundColor: AppTheme.blush,
                        labelStyle: const TextStyle(
                          color: AppTheme.cocoa,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapExperienceCard extends StatelessWidget {
  const _MapExperienceCard({
    required this.markers,
    required this.selectedRestaurant,
    required this.perlisCenter,
    required this.userLocation,
    required this.nearMeOnly,
  });

  final Set<Marker> markers;
  final Restaurant? selectedRestaurant;
  final LatLng perlisCenter;
  final LatLng? userLocation;
  final bool nearMeOnly;

  @override
  Widget build(BuildContext context) {
    final cameraTarget = selectedRestaurant != null
        ? LatLng(selectedRestaurant!.lat, selectedRestaurant!.lng)
        : nearMeOnly && userLocation != null
            ? userLocation!
            : perlisCenter;
    final zoom = selectedRestaurant != null
        ? 16.0
        : nearMeOnly && userLocation != null
            ? 14.0
            : 13.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 240,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: cameraTarget,
                  zoom: zoom,
                ),
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedRestaurant == null
                      ? nearMeOnly && userLocation != null
                          ? 'You are seeing restaurants within 10 km of your current location.'
                          : 'Tap a marker or restaurant card to zoom in on the next place that feels promising.'
                      : 'Selected now: ${selectedRestaurant!.name}',
                  style: const TextStyle(
                    color: AppTheme.cocoa,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedRestaurant == null
                      ? 'Use the map to get your bearings, then open the details when you are ready to save or review.'
                      : selectedRestaurant!.address,
                  style: TextStyle(
                    color: Colors.brown.shade400,
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

class _ExploreRestaurantCard extends StatelessWidget {
  const _ExploreRestaurantCard({
    required this.restaurant,
    required this.ratingSummary,
    required this.distanceLabel,
    required this.areaLabel,
    required this.isFavourite,
    required this.onOpen,
    required this.onSave,
    required this.onReview,
  });

  final Restaurant restaurant;
  final String ratingSummary;
  final String distanceLabel;
  final String areaLabel;
  final bool isFavourite;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final halalForeground = restaurant.halalStatus == 'Halal'
        ? const Color(0xFF2F7A4A)
        : restaurant.halalStatus == 'Non-halal'
            ? const Color(0xFF9D3243)
            : const Color(0xFF8A5C49);
    final halalBackground = restaurant.halalStatus == 'Halal'
        ? const Color(0xFFE8F7EE)
        : restaurant.halalStatus == 'Non-halal'
            ? const Color(0xFFFFEAEF)
            : const Color(0xFFFFF5E9);
    final detailsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniBadge(
              icon: Icons.star_rounded,
              label: ratingSummary,
              backgroundColor: const Color(0xFFFFF2D9),
              foregroundColor: const Color(0xFF9A6504),
            ),
            _MiniBadge(
              icon: Icons.restaurant_menu_rounded,
              label: restaurant.restaurantType,
              backgroundColor: AppTheme.blush,
              foregroundColor: AppTheme.clay,
            ),
            _MiniBadge(
              icon: restaurant.halalStatus == 'Non-halal'
                  ? Icons.no_food_rounded
                  : Icons.verified_outlined,
              label: restaurant.halalStatus,
              backgroundColor: halalBackground,
              foregroundColor: halalForeground,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          restaurant.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 19,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: AppTheme.cocoa,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          restaurant.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.brown.shade400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _InlineStat(
              icon: Icons.place_outlined,
              label: areaLabel,
            ),
            if (distanceLabel.isNotEmpty)
              _InlineStat(
                icon: Icons.near_me_outlined,
                label: distanceLabel,
              ),
            _InlineStat(
              icon: restaurant.isOpen == true
                  ? Icons.schedule_rounded
                  : Icons.info_outline_rounded,
              label: restaurant.status,
              foregroundColor: restaurant.isOpen == true
                  ? const Color(0xFF2F7A4A)
                  : AppTheme.mutedBrown,
            ),
          ],
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onOpen,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (isCompact) ...[
                    _RestaurantThumb(
                      imageUrl: restaurant.image,
                      width: double.infinity,
                      height: 176,
                    ),
                    const SizedBox(height: 14),
                    detailsSection,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RestaurantThumb(imageUrl: restaurant.image),
                        const SizedBox(width: 14),
                        Expanded(child: detailsSection),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: onReview,
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('Review'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF2E6),
                          foregroundColor: AppTheme.clay,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: onSave,
                        icon: Icon(
                          isFavourite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                        label: Text(isFavourite ? 'Saved' : 'Save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isFavourite
                              ? const Color(0xFFFFE8EC)
                              : const Color(0xFFFFF7F0),
                          foregroundColor: isFavourite
                              ? const Color(0xFFC13E57)
                              : AppTheme.cocoa,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RestaurantThumb extends StatelessWidget {
  const _RestaurantThumb({
    required this.imageUrl,
    this.width = 110,
    this.height = 118,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl.trim().isEmpty
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFD9C0),
                      Color(0xFFF6A76B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFFFE5D6),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppTheme.clay,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFD9C0),
                        Color(0xFFF6A76B),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
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
    final maxChipWidth = MediaQuery.sizeOf(context).width * 0.52;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: foregroundColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
    required this.icon,
    required this.label,
    this.foregroundColor = AppTheme.mutedBrown,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.48;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.availableTypes,
    required this.availableAreas,
    required this.initialType,
    required this.initialArea,
    required this.initialNearMeOnly,
  });

  final List<String> availableTypes;
  final List<String> availableAreas;
  final String? initialType;
  final String? initialArea;
  final bool initialNearMeOnly;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selectedType;
  late String? _selectedArea;
  late bool _nearMeOnly;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedArea = widget.initialArea;
    _nearMeOnly = widget.initialNearMeOnly;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: AppTheme.warmWhite,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Refine Your Food Trail',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.cocoa,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a food style, area, or combine it with Near Me for a quicker decision.',
                  style: TextStyle(
                    color: Colors.brown.shade400,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Restaurant Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.cocoa,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.availableTypes
                      .map(
                        (type) => ChoiceChip(
                          label: Text(type),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = selected ? type : null;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Area',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.cocoa,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.availableAreas
                      .map(
                        (area) => ChoiceChip(
                          label: Text(area),
                          selected: _selectedArea == area,
                          onSelected: (selected) {
                            setState(() {
                              _selectedArea = selected ? area : null;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  value: _nearMeOnly,
                  onChanged: (value) {
                    setState(() {
                      _nearMeOnly = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Restaurant near me',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.cocoa,
                    ),
                  ),
                  subtitle: const Text(
                    'Requests your location and keeps restaurants within 10 km.',
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedType = null;
                            _selectedArea = null;
                            _nearMeOnly = false;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _FilterDraft(
                              type: _selectedType,
                              area: _selectedArea,
                              nearMeOnly: _nearMeOnly,
                            ),
                          );
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginRequiredSheet extends StatelessWidget {
  const _LoginRequiredSheet({
    required this.actionLabel,
    required this.actionDescription,
    required this.icon,
  });

  final String actionLabel;
  final String actionDescription;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 48, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          decoration: const BoxDecoration(
            color: AppTheme.warmWhite,
            borderRadius: BorderRadius.all(Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFD75A25),
                      Color(0xFFF09D36),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login required',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Keep your food trail personal and saved to your account.',
                            style: TextStyle(
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.cocoa,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                actionDescription,
                style: TextStyle(
                  color: Colors.brown.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppTheme.clay,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After signing in, your saved places and reviews will be attached to your own journal in Firebase.',
                        style: TextStyle(
                          color: AppTheme.cocoa,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Login / Sign Up'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Maybe later'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreStateMessage extends StatelessWidget {
  const _ExploreStateMessage({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppTheme.blush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 38,
                  color: AppTheme.clay,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.cocoa,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.brown.shade400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewDraft {
  const _ReviewDraft({
    required this.rating,
    required this.deliciousScale,
    required this.text,
  });

  final double rating;
  final double deliciousScale;
  final String text;
}

class _FilterDraft {
  const _FilterDraft({
    required this.type,
    required this.area,
    required this.nearMeOnly,
  });

  final String? type;
  final String? area;
  final bool nearMeOnly;
}

class _ActiveFilterChipData {
  const _ActiveFilterChipData({
    required this.label,
    required this.onRemoved,
  });

  final String label;
  final VoidCallback onRemoved;
}

String _deliciousScaleLabel(double value) {
  switch (value.round()) {
    case 1:
      return 'Not for me';
    case 2:
      return 'Just okay';
    case 3:
      return 'Tasty';
    case 4:
      return 'Very delicious';
    case 5:
      return 'Must order again';
    default:
      return 'Tasty';
  }
}
