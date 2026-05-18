import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Dashboard'),
              SizedBox(height: 2),
              Text(
                'RasaJourney content control',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mutedBrown,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: () async {
                await AuthService.signOut();
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin logged out.')),
                );
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Restaurants'),
              Tab(icon: Icon(Icons.category_outlined), text: 'Categories'),
              Tab(icon: Icon(Icons.rate_review_outlined), text: 'Reviews'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                if (tabController.index == 0) {
                  return FloatingActionButton.extended(
                    onPressed: () => _openRestaurantEditor(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Restaurant'),
                  );
                }
                if (tabController.index == 1) {
                  return FloatingActionButton.extended(
                    onPressed: () => _openCategoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Category'),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
        body: TabBarView(
          children: [
            _RestaurantsAdminTab(
              adminService: _adminService,
              onEdit: (restaurant) =>
                  _openRestaurantEditor(context, restaurant: restaurant),
            ),
            _CategoriesAdminTab(adminService: _adminService),
            _ReviewsAdminTab(adminService: _adminService),
            _AnalyticsAdminTab(adminService: _adminService),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    final categoryName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category name',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (categoryName == null || categoryName.isEmpty) {
      return;
    }

    await _runAdminAction(
      action: () => _adminService.saveCategory(categoryName),
      successMessage: 'Category saved.',
    );
  }

  Future<void> _openRestaurantEditor(
    BuildContext context, {
    Restaurant? restaurant,
  }) async {
    final draft = await showDialog<_RestaurantDraft>(
      context: context,
      builder: (dialogContext) =>
          _RestaurantEditorDialog(restaurant: restaurant),
    );

    if (draft == null) {
      return;
    }

    await _runAdminAction(
      action: () => _adminService.saveRestaurant(
        id: restaurant?.id,
        restaurant: draft.toRestaurant(id: restaurant?.id ?? ''),
      ),
      successMessage: restaurant == null
          ? 'Restaurant added.'
          : 'Restaurant updated.',
    );
  }

  Future<void> _runAdminAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Admin action failed: $error')));
    }
  }
}

class _RestaurantsAdminTab extends StatelessWidget {
  const _RestaurantsAdminTab({
    required this.adminService,
    required this.onEdit,
  });

  final AdminService adminService;
  final ValueChanged<Restaurant> onEdit;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: adminService.restaurantsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AdminStateMessage(
            icon: Icons.error_outline,
            title: 'Could not load restaurants.',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final restaurants = snapshot.data!;
        if (restaurants.isEmpty) {
          return const _AdminStateMessage(
            icon: Icons.restaurant_menu,
            title: 'No restaurants yet.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: restaurants.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return _AdminListCard(
              title: restaurant.name,
              subtitle: restaurant.address,
              icon: Icons.restaurant_menu,
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    onEdit(restaurant);
                    return;
                  }
                  if (value == 'delete') {
                    final confirmed = await _confirmDelete(
                      context,
                      'Delete ${restaurant.name}?',
                    );
                    if (confirmed && context.mounted) {
                      await adminService.deleteRestaurant(restaurant.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Restaurant deleted.')),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              chips: [
                restaurant.restaurantType,
                restaurant.halalStatus,
                restaurant.status,
              ],
            );
          },
        );
      },
    );
  }
}

class _CategoriesAdminTab extends StatelessWidget {
  const _CategoriesAdminTab({required this.adminService});

  final AdminService adminService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: adminService.restaurantsStream(),
      builder: (context, restaurantsSnapshot) {
        final derivedCategories = {
          for (final restaurant in restaurantsSnapshot.data ?? <Restaurant>[])
            if (restaurant.restaurantType.trim().isNotEmpty)
              restaurant.restaurantType.trim(),
        }.toList()..sort();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: adminService.categoriesStream(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _AdminSectionHeader(
                  title: 'Saved Categories',
                  subtitle: '${docs.length} custom categories',
                ),
                const SizedBox(height: 12),
                if (!snapshot.hasData)
                  const Center(child: CircularProgressIndicator())
                else if (docs.isEmpty)
                  const _AdminStateMessage(
                    icon: Icons.category_outlined,
                    title: 'No custom categories saved yet.',
                    shrink: true,
                  )
                else
                  ...docs.map((doc) {
                    final name = (doc.data()['name'] ?? doc.id).toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AdminListCard(
                        title: name,
                        subtitle: 'Available for admin organization',
                        icon: Icons.category_outlined,
                        trailing: IconButton(
                          tooltip: 'Delete category',
                          onPressed: () async {
                            final confirmed = await _confirmDelete(
                              context,
                              'Delete $name?',
                            );
                            if (confirmed && context.mounted) {
                              await adminService.deleteCategory(doc.id);
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 18),
                _AdminSectionHeader(
                  title: 'Restaurant Types In Use',
                  subtitle:
                      '${derivedCategories.length} detected from restaurants',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: derivedCategories
                      .map((category) => Chip(label: Text(category)))
                      .toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ReviewsAdminTab extends StatelessWidget {
  const _ReviewsAdminTab({required this.adminService});

  final AdminService adminService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: adminService.reviewsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AdminStateMessage(
            icon: Icons.error_outline,
            title: 'Could not load reviews.',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const _AdminStateMessage(
            icon: Icons.rate_review_outlined,
            title: 'No user reviews yet.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final text = (data['text'] ?? '').toString();
            final restaurantName = (data['restaurantName'] ?? 'Restaurant')
                .toString();
            final userEmail = (data['userEmail'] ?? 'Unknown user').toString();
            final rating = (data['rating'] as num?)?.toDouble() ?? 0;

            return _AdminListCard(
              title: restaurantName,
              subtitle: '$userEmail\n$text',
              icon: Icons.rate_review_outlined,
              trailing: IconButton(
                tooltip: 'Delete review',
                onPressed: () async {
                  final confirmed = await _confirmDelete(
                    context,
                    'Delete this review?',
                  );
                  if (confirmed && context.mounted) {
                    await adminService.deleteReview(data, doc.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review deleted.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline),
              ),
              chips: ['${rating.toStringAsFixed(1)} stars'],
            );
          },
        );
      },
    );
  }
}

class _AnalyticsAdminTab extends StatelessWidget {
  const _AnalyticsAdminTab({required this.adminService});

  final AdminService adminService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: adminService.restaurantsStream(),
      builder: (context, restaurantsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: adminService.reviewsStream(),
          builder: (context, reviewsSnapshot) {
            final restaurants = restaurantsSnapshot.data ?? <Restaurant>[];
            final reviews = reviewsSnapshot.data?.docs ?? [];
            final categories = {
              for (final restaurant in restaurants)
                if (restaurant.restaurantType.trim().isNotEmpty)
                  restaurant.restaurantType.trim(),
            };
            final averageRating = restaurants.isEmpty
                ? 0.0
                : restaurants
                          .map((restaurant) => restaurant.rating)
                          .fold<double>(0, (total, rating) => total + rating) /
                      restaurants.length;
            final halalCount = restaurants
                .where((restaurant) => restaurant.halalStatus == 'Halal')
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AdminSectionHeader(
                  title: 'Analytics',
                  subtitle: 'Live Firestore snapshot summary',
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 700
                      ? 4
                      : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: MediaQuery.sizeOf(context).width > 700
                      ? 1.35
                      : 1.05,
                  children: [
                    _MetricCard(
                      icon: Icons.restaurant_menu,
                      label: 'Restaurants',
                      value: '${restaurants.length}',
                    ),
                    _MetricCard(
                      icon: Icons.category_outlined,
                      label: 'Categories',
                      value: '${categories.length}',
                    ),
                    _MetricCard(
                      icon: Icons.rate_review_outlined,
                      label: 'Reviews',
                      value: '${reviews.length}',
                    ),
                    _MetricCard(
                      icon: Icons.star_rounded,
                      label: 'Avg Rating',
                      value: averageRating.toStringAsFixed(1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AdminListCard(
                  title: 'Halal Restaurants',
                  subtitle:
                      '$halalCount of ${restaurants.length} restaurants marked halal',
                  icon: Icons.verified_outlined,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RestaurantEditorDialog extends StatefulWidget {
  const _RestaurantEditorDialog({this.restaurant});

  final Restaurant? restaurant;

  @override
  State<_RestaurantEditorDialog> createState() =>
      _RestaurantEditorDialogState();
}

class _RestaurantEditorDialogState extends State<_RestaurantEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _halalController;
  late final TextEditingController _statusController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _imageController;
  late final TextEditingController _menuController;
  late final TextEditingController _hoursController;
  String? _selectedRestaurantType;

  @override
  void initState() {
    super.initState();
    final restaurant = widget.restaurant;
    _nameController = TextEditingController(text: restaurant?.name ?? '');
    _addressController = TextEditingController(text: restaurant?.address ?? '');
    _selectedRestaurantType =
        restaurant?.restaurantType.trim().isNotEmpty == true
        ? restaurant!.restaurantType.trim()
        : null;
    _halalController = TextEditingController(
      text: restaurant?.halalStatus ?? 'Halal',
    );
    _statusController = TextEditingController(
      text: restaurant?.status ?? 'Operational',
    );
    _latController = TextEditingController(
      text: restaurant == null ? '' : restaurant.lat.toString(),
    );
    _lngController = TextEditingController(
      text: restaurant == null ? '' : restaurant.lng.toString(),
    );
    _imageController = TextEditingController(text: restaurant?.image ?? '');
    _menuController = TextEditingController(
      text: restaurant?.menuItems.join(', ') ?? '',
    );
    _hoursController = TextEditingController(
      text: restaurant?.operatingHours.join('\n') ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _halalController.dispose();
    _statusController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _imageController.dispose();
    _menuController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.restaurant == null ? 'Add Restaurant' : 'Edit Restaurant',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _requiredTextField(_nameController, 'Restaurant name'),
                const SizedBox(height: 12),
                _requiredTextField(_addressController, 'Address', maxLines: 2),
                const SizedBox(height: 12),
                _RestaurantTypeDropdown(
                  adminService: _adminService,
                  selectedType: _selectedRestaurantType,
                  onChanged: (value) {
                    setState(() {
                      _selectedRestaurantType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _halalController,
                  decoration: const InputDecoration(labelText: 'Halal status'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _statusController,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _numberTextField(_latController, 'Latitude'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberTextField(_lngController, 'Longitude'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _menuController,
                  decoration: const InputDecoration(
                    labelText: 'Menu items',
                    hintText: 'Separate items with commas',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hoursController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Operating hours',
                    hintText: 'One line per day or period',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.pop(
              context,
              _RestaurantDraft(
                name: _nameController.text.trim(),
                address: _addressController.text.trim(),
                restaurantType: _selectedRestaurantType!.trim(),
                halalStatus: _halalController.text.trim(),
                status: _statusController.text.trim(),
                lat: double.parse(_latController.text.trim()),
                lng: double.parse(_lngController.text.trim()),
                image: _imageController.text.trim(),
                menuItems: _splitCommaValues(_menuController.text),
                operatingHours: _splitLineValues(_hoursController.text),
                existing: widget.restaurant,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _requiredTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }
        return null;
      },
    );
  }

  Widget _numberTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null) {
          return 'Enter a valid number.';
        }
        return null;
      },
    );
  }
}

class _RestaurantTypeDropdown extends StatelessWidget {
  const _RestaurantTypeDropdown({
    required this.adminService,
    required this.selectedType,
    required this.onChanged,
  });

  final AdminService adminService;
  final String? selectedType;
  final ValueChanged<String?> onChanged;

  static const List<String> _defaultTypes = [
    'Authentic Malay Cuisine',
    'Local Cuisine',
    'Street Food',
    'Food Court',
    'Cafe & Coffee',
    'Thai',
    'Chinese Cuisine',
    'Indian Cuisine',
    'Korean Cuisine',
    'Western',
    'Seafood',
    'BBQ & Grill',
    'Fast Food',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: adminService.restaurantsStream(),
      builder: (context, restaurantsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: adminService.categoriesStream(),
          builder: (context, categoriesSnapshot) {
            final options = _buildTypeOptions(
              restaurantsSnapshot.data ?? const <Restaurant>[],
              categoriesSnapshot.data?.docs ?? const [],
              selectedType,
            );

            return DropdownButtonFormField<String>(
              initialValue:
                  selectedType != null && options.contains(selectedType)
                  ? selectedType
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category / type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: options
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Category / type is required.';
                }
                return null;
              },
            );
          },
        );
      },
    );
  }

  List<String> _buildTypeOptions(
    List<Restaurant> restaurants,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> categoryDocs,
    String? currentValue,
  ) {
    final values = <String>{
      ..._defaultTypes,
      for (final restaurant in restaurants)
        if (restaurant.restaurantType.trim().isNotEmpty)
          restaurant.restaurantType.trim(),
      for (final doc in categoryDocs)
        if ((doc.data()['name'] ?? '').toString().trim().isNotEmpty)
          (doc.data()['name'] ?? '').toString().trim(),
      if (currentValue != null && currentValue.trim().isNotEmpty)
        currentValue.trim(),
    }.toList()..sort();

    return values;
  }
}

class _RestaurantDraft {
  const _RestaurantDraft({
    required this.name,
    required this.address,
    required this.restaurantType,
    required this.halalStatus,
    required this.status,
    required this.lat,
    required this.lng,
    required this.image,
    required this.menuItems,
    required this.operatingHours,
    required this.existing,
  });

  final String name;
  final String address;
  final String restaurantType;
  final String halalStatus;
  final String status;
  final double lat;
  final double lng;
  final String image;
  final List<String> menuItems;
  final List<String> operatingHours;
  final Restaurant? existing;

  Restaurant toRestaurant({required String id}) {
    return Restaurant(
      id: id,
      placeId: existing?.placeId,
      name: name,
      address: address,
      image: image,
      lat: lat,
      lng: lng,
      rating: existing?.rating ?? 0,
      ratingCount: existing?.ratingCount ?? 0,
      reviews: existing?.reviews ?? const [],
      operatingHours: operatingHours,
      isOpen: existing?.isOpen,
      status: status,
      restaurantType: restaurantType,
      halalStatus: halalStatus,
      menuItems: menuItems,
      galleryImages: existing?.galleryImages ?? const [],
    );
  }
}

class _AdminListCard extends StatelessWidget {
  const _AdminListCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.chips = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.sand),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppTheme.blush,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.clay),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppTheme.cocoa,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.mutedBrown),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips
                        .where((chip) => chip.trim().isNotEmpty)
                        .map((chip) => Chip(label: Text(chip)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.clay, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.cocoa,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.mutedBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  const _AdminSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.cocoa,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.mutedBrown),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminStateMessage extends StatelessWidget {
  const _AdminStateMessage({
    required this.icon,
    required this.title,
    this.shrink = false,
  });

  final IconData icon;
  final String title;
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: shrink ? 1 : null,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppTheme.clay),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.cocoa,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String title) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false;
}

List<String> _splitCommaValues(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<String> _splitLineValues(String value) {
  return value
      .split(RegExp(r'[\r\n]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
