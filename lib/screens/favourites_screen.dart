import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../widgets/main_nav_scope.dart';
import '../widgets/smart_back_button.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'restaurant_detail_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data ?? AuthService.currentUser;

        if (user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFF8F3),
            appBar: AppBar(
              leading: SmartBackButton(
                fallback: MainNavScope.maybeOf(context)?.goHome,
              ),
              title: const Text('My Food Journal'),
              backgroundColor: const Color(0xFFFFF8F3),
              foregroundColor: const Color(0xFF4A2D24),
              surfaceTintColor: Colors.transparent,
            ),
            body: _LoggedOutState(
              onLoginPressed: () => AuthScreen.open(context),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFF8F3),
          appBar: AppBar(
            leading: SmartBackButton(
              fallback: MainNavScope.maybeOf(context)?.goHome,
            ),
            title: const Text('My Food Journal'),
            backgroundColor: const Color(0xFFFFF8F3),
            foregroundColor: const Color(0xFF4A2D24),
            surfaceTintColor: Colors.transparent,
            actions: [
              if (user != null)
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(user: user),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_outline),
                ),
              if (user != null)
                IconButton(
                  tooltip: 'Logout',
                  onPressed: () async {
                    await AuthService.signOut();
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),
          body: StreamBuilder<UserProfile>(
            stream: AuthService.userProfileStream(user),
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.hasData
                  ? profileSnapshot.data!
                  : UserProfile.fromSources(user, null);

              return DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: _ProfileHero(
                          profile: profile,
                          onEditProfile: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(user: user),
                              ),
                            );
                          },
                        ),
                      ),
                      const SliverPersistentHeader(
                        pinned: true,
                        delegate: _JournalTabHeaderDelegate(),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      _FavouritesTab(user: user),
                      _ReviewsTab(user: user),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LoggedOutState extends StatelessWidget {
  const _LoggedOutState({
    required this.onLoginPressed,
  });

  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF2E7),
            Color(0xFFFFFBF7),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepOrange.shade400,
                            Colors.orange.shade300,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Build your personal food journal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF45271C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Login first to save favourite spots, write reviews, and keep your profile ready for the next food adventure.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.brown.shade400,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onLoginPressed,
                      icon: const Icon(Icons.login),
                      label: const Text('Login / Sign Up'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.onEditProfile,
  });

  final UserProfile profile;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final userPath = FirebaseFirestore.instance.collection('users').doc(profile.uid);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD44A1C),
              Color(0xFFE36A1F),
              Color(0xFFF0A43B),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          profile.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onEditProfile,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    profile.headline,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      height: 1.5,
                    ),
                  ),
                  if (profile.hometown.isNotEmpty || profile.phone.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (profile.hometown.isNotEmpty)
                          _HeroTag(
                            icon: Icons.location_on_outlined,
                            label: profile.hometown,
                          ),
                        if (profile.phone.isNotEmpty)
                          _HeroTag(
                            icon: Icons.phone_outlined,
                            label: profile.phone,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: userPath.collection('favourites').snapshots(),
                          builder: (context, snapshot) {
                            return _StatTile(
                              label: 'Saved Spots',
                              value: '${snapshot.data?.docs.length ?? 0}',
                              icon: Icons.favorite_rounded,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: userPath.collection('reviews').snapshots(),
                          builder: (context, snapshot) {
                            return _StatTile(
                              label: 'Your Reviews',
                              value: '${snapshot.data?.docs.length ?? 0}',
                              icon: Icons.rate_review_rounded,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
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

class _JournalTabBar extends StatelessWidget {
  const _JournalTabBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0DED0)),
      ),
      child: const TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFF8C5B45),
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          gradient: LinearGradient(
            colors: [
              Color(0xFFD44A1C),
              Color(0xFFF0972F),
            ],
          ),
        ),
        tabs: [
          Tab(text: 'Favourites', icon: Icon(Icons.favorite_rounded)),
          Tab(text: 'Reviews', icon: Icon(Icons.rate_review_rounded)),
        ],
      ),
    );
  }
}

class _JournalTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _JournalTabHeaderDelegate();

  static const double _height = 74;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFFFF8F3),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      alignment: Alignment.center,
      child: const _JournalTabBar(),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _FavouritesTab extends StatelessWidget {
  const _FavouritesTab({
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favourites')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ScrollableState(
            child: Text('Could not load favourites.'),
          );
        }

        if (!snapshot.hasData) {
          return const _ScrollableState(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_outline,
            title: 'No saved restaurants yet',
            subtitle: 'When you find a place you love in Explore, save it here for quick access later.',
          );
        }

        return ListView.separated(
          key: const PageStorageKey<String>('favourites-tab'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final restaurant = Restaurant.fromMap(data, id: docs[index].id);
            final savedAt = data['savedAt'] as Timestamp?;

            return InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestaurantDetailScreen(
                      restaurant: restaurant,
                    ),
                  ),
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _RestaurantThumbnail(imageUrl: restaurant.image),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                const _InfoChip(
                                  label: 'Saved',
                                  icon: Icons.favorite_rounded,
                                  color: Color(0xFFFFEFE5),
                                  foregroundColor: Color(0xFFB5481E),
                                ),
                                if (restaurant.status.isNotEmpty)
                                  _InfoChip(
                                    label: restaurant.status,
                                    icon: restaurant.isOpen == true
                                        ? Icons.schedule
                                        : Icons.info_outline,
                                    color: restaurant.isOpen == true
                                        ? const Color(0xFFE7F7EE)
                                        : const Color(0xFFFFF3E6),
                                    foregroundColor: restaurant.isOpen == true
                                        ? const Color(0xFF2F7A4A)
                                        : const Color(0xFF8C5B45),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              restaurant.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3E251D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              restaurant.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.brown.shade400,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (restaurant.rating > 0)
                                  Text(
                                    '${restaurant.rating.toStringAsFixed(1)} rating',
                                    style: const TextStyle(
                                      color: Color(0xFFB5481E),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                else
                                  Text(
                                    'Ready for your next visit',
                                    style: TextStyle(
                                      color: Colors.brown.shade400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                const Spacer(),
                                if (savedAt != null)
                                  Text(
                                    _formatDate(savedAt),
                                    style: TextStyle(
                                      color: Colors.brown.shade300,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFFB5481E),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ScrollableState(
            child: Text('Could not load reviews.'),
          );
        }

        if (!snapshot.hasData) {
          return const _ScrollableState(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.rate_review_outlined,
            title: 'No reviews written yet',
            subtitle: 'After trying a restaurant from Explore, your notes and ratings will show up here.',
          );
        }

        return ListView.separated(
          key: const PageStorageKey<String>('reviews-tab'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final rating = (data['rating'] as num?)?.toDouble() ?? 0;
            final deliciousScale =
                (data['deliciousScale'] as num?)?.toDouble() ?? 0;
            final reviewText = (data['text'] ?? '').toString().trim();
            final timestamp = data['timestamp'] as Timestamp?;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['restaurantName'] ?? 'Restaurant').toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3E251D),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (data['restaurantAddress'] ?? '').toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.brown.shade400,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1D8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF2A31D),
                              ),
                              Text(
                                rating.toStringAsFixed(
                                  rating.truncateToDouble() == rating ? 0 : 1,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8A5A0E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (deliciousScale > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_outlined,
                            size: 18,
                            color: Color(0xFFD45720),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Delicious scale ${deliciousScale.toInt()}/5',
                            style: const TextStyle(
                              color: Color(0xFFD45720),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: List.generate(
                        5,
                        (starIndex) => Icon(
                          starIndex < rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 20,
                          color: const Color(0xFFF2A31D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reviewText.isEmpty
                            ? 'No review text was added for this rating.'
                            : '"$reviewText"',
                        style: TextStyle(
                          color: Colors.brown.shade600,
                          height: 1.55,
                          fontStyle: reviewText.isEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const _InfoChip(
                          label: 'Your review',
                          icon: Icons.edit_note_rounded,
                          color: Color(0xFFFFEFE5),
                          foregroundColor: Color(0xFFB5481E),
                        ),
                        const Spacer(),
                        if (timestamp != null)
                          Text(
                            _formatDate(timestamp),
                            style: TextStyle(
                              color: Colors.brown.shade300,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RestaurantThumbnail extends StatelessWidget {
  const _RestaurantThumbnail({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 108,
        height: 118,
        child: imageUrl.trim().isEmpty
            ? Container(
                color: const Color(0xFFFFE5D6),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 38,
                  color: Color(0xFFB5481E),
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
                      color: Color(0xFFB5481E),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFFFE5D6),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFB5481E),
                  ),
                ),
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.48,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEFE5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 38,
                      color: const Color(0xFFB5481E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF45271C),
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
        ),
      ],
    );
  }
}

class _ScrollableState extends StatelessWidget {
  const _ScrollableState({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 32),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(child: child),
        ),
      ],
    );
  }
}

String _formatDate(Timestamp timestamp) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final date = timestamp.toDate();
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
