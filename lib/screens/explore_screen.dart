import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  Future<User?> _requireSignedInUser() async {
    final existingUser = AuthService.currentUser;
    if (existingUser != null) {
      await AuthService.syncUserProfile(existingUser);
      return existingUser;
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
    final user = await _requireSignedInUser();
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
    final user = await _requireSignedInUser();
    if (user == null) {
      return;
    }

    final reviewDraft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (dialogContext) {
        final reviewController = TextEditingController();
        double rating = 4;
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
                    Text(
                      'What feeling stayed with you after this meal?',
                      style: TextStyle(
                        color: Colors.brown.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Your rating'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          onPressed: () {
                            setDialogState(() {
                              rating = index + 1.0;
                            });
                          },
                          icon: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFF2A31D),
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reviewController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Describe the taste, vibe, or memory you want to keep...',
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
                        errorText = 'Please write a short review before submitting.';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _ReviewDraft(rating: rating, text: text),
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
                icon: Icon(
                  user == null
                      ? Icons.account_circle_outlined
                      : Icons.account_circle,
                  color: AppTheme.cocoa,
                ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by restaurant or area',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? const Icon(Icons.tune_rounded)
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
        ),
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

            if (selectedRestaurant != null &&
                !filteredRestaurants.any(
                  (restaurant) => restaurant.name == selectedRestaurant!.name,
                )) {
              selectedRestaurant = null;
            }

            if (filteredRestaurants.isEmpty) {
              return _ExploreStateMessage(
                title: 'No restaurants match that search yet.',
                subtitle: _searchController.text.trim().isEmpty
                    ? 'Try again in a moment.'
                    : 'Try another name or nearby area to keep exploring.',
              );
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

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _ExploreHeroPanel(
                              restaurantCount: filteredRestaurants.length,
                              selectedRestaurant: selectedRestaurant,
                              query: _searchController.text.trim(),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _MapExperienceCard(
                              markers: markers,
                              selectedRestaurant: selectedRestaurant,
                              perlisCenter: _perlisCenter,
                            ),
                          ),
                        ),
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
                                    bottom: index == filteredRestaurants.length - 1
                                        ? 0
                                        : 14,
                                  ),
                                  child: _ExploreRestaurantCard(
                                    restaurant: restaurant,
                                    isFavourite: isFavourite,
                                    onOpen: () {
                                      setState(() {
                                        selectedRestaurant = restaurant;
                                      });
                                      _openRestaurantDetails(restaurant);
                                    },
                                    onSave: () => _toggleFavourite(restaurant),
                                    onReview: () => _showReviewDialog(restaurant),
                                  ),
                                );
                              },
                              childCount: filteredRestaurants.length,
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
  });

  final int restaurantCount;
  final Restaurant? selectedRestaurant;
  final String query;

  @override
  Widget build(BuildContext context) {
    final title = query.isEmpty
        ? 'A warm food trail is waiting.'
        : 'Results for "$query"';
    final subtitle = selectedRestaurant == null
        ? 'Browse nearby restaurants, save the ones that feel special, and keep building your return list.'
        : 'You are currently focused on ${selectedRestaurant!.name}. Open it to capture the details while the mood is fresh.';

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
              _HeroPill(
                icon: Icons.favorite_border_rounded,
                label: 'Save for later',
              ),
              _HeroPill(
                icon: Icons.rate_review_outlined,
                label: 'Review honestly',
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

class _MapExperienceCard extends StatelessWidget {
  const _MapExperienceCard({
    required this.markers,
    required this.selectedRestaurant,
    required this.perlisCenter,
  });

  final Set<Marker> markers;
  final Restaurant? selectedRestaurant;
  final LatLng perlisCenter;

  @override
  Widget build(BuildContext context) {
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
                  target: selectedRestaurant != null
                      ? LatLng(
                          selectedRestaurant!.lat,
                          selectedRestaurant!.lng,
                        )
                      : perlisCenter,
                  zoom: selectedRestaurant != null ? 16 : 13,
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
                      ? 'Tap a marker or restaurant card to zoom in on the next place that feels promising.'
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
    required this.isFavourite,
    required this.onOpen,
    required this.onSave,
    required this.onReview,
  });

  final Restaurant restaurant;
  final bool isFavourite;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final ratingLabel = restaurant.rating > 0
        ? '${restaurant.rating.toStringAsFixed(1)} (${restaurant.ratingCount})'
        : restaurant.status;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RestaurantThumb(imageUrl: restaurant.image),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniBadge(
                              icon: Icons.place_outlined,
                              label: 'Perlis',
                              backgroundColor: AppTheme.blush,
                              foregroundColor: AppTheme.clay,
                            ),
                            _MiniBadge(
                              icon: restaurant.isOpen == true
                                  ? Icons.schedule_rounded
                                  : Icons.info_outline_rounded,
                              label: restaurant.status,
                              backgroundColor: restaurant.isOpen == true
                                  ? const Color(0xFFE8F7EE)
                                  : const Color(0xFFFFF5E9),
                              foregroundColor: restaurant.isOpen == true
                                  ? const Color(0xFF2F7A4A)
                                  : const Color(0xFF8A5C49),
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
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF2A31D),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ratingLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.clay,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onReview,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Review'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF2E6),
                      foregroundColor: AppTheme.clay,
                    ),
                  ),
                  FilledButton.tonalIcon(
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
  }
}

class _RestaurantThumb extends StatelessWidget {
  const _RestaurantThumb({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 110,
        height: 118,
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
    return Container(
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
    required this.text,
  });

  final double rating;
  final String text;
}
