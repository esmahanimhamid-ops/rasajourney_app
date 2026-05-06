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
  final String restaurantType;
  final String halalStatus;
  final List<String> menuItems;
  final List<String> galleryImages;

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
    required this.restaurantType,
    required this.halalStatus,
    required this.menuItems,
    required this.galleryImages,
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
    final reviews = _toStringList(data['reviews']);
    final image = (data['image'] ?? data['imageUrl'] ?? '').toString();
    final galleryImages = _buildGalleryImages(data, image);
    final restaurantType = _parseRestaurantType(
      data,
      name: (data['name'] ?? '').toString(),
      address: addressValue.toString(),
      reviews: reviews,
    );

    return Restaurant(
      id: id,
      placeId: data['placeId']?.toString(),
      name: (data['name'] ?? '').toString(),
      address: addressValue.toString(),
      image: image,
      lat: (latValue as num).toDouble(),
      lng: (lngValue as num).toDouble(),
      rating: _toDouble(data['rating']),
      ratingCount: _toInt(data['ratingCount']),
      reviews: reviews,
      operatingHours: _toStringList(
        data['operatingHours'] ?? data['openingHours'] ?? data['hours'],
      ),
      isOpen: isOpenValue,
      status: _parseStatus(data, isOpenValue),
      restaurantType: restaurantType,
      halalStatus: _parseHalalStatus(
        data,
        name: (data['name'] ?? '').toString(),
        reviews: reviews,
        restaurantType: restaurantType,
      ),
      menuItems: _parseMenuItems(
        data,
        name: (data['name'] ?? '').toString(),
        reviews: reviews,
        restaurantType: restaurantType,
      ),
      galleryImages: galleryImages,
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
    String? restaurantType,
    String? halalStatus,
    List<String>? menuItems,
    List<String>? galleryImages,
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
      restaurantType: restaurantType ?? this.restaurantType,
      halalStatus: halalStatus ?? this.halalStatus,
      menuItems: menuItems ?? this.menuItems,
      galleryImages: galleryImages ?? this.galleryImages,
    );
  }

  bool get hasKnownHalalStatus =>
      halalStatus == 'Halal' || halalStatus == 'Non-halal';

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

  static List<String> _toSplitStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[|,;/]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static List<String> _toUrlList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) {
            if (item is Map) {
              return item['url']?.toString().trim() ??
                  item['imageUrl']?.toString().trim() ??
                  '';
            }
            return item?.toString().trim() ?? '';
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[|,]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static List<String> _buildGalleryImages(
    Map<String, dynamic> data,
    String primaryImage,
  ) {
    final images = <String>[
      if (primaryImage.trim().isNotEmpty) primaryImage.trim(),
      ..._toUrlList(
        data['galleryImages'] ??
            data['dishImages'] ??
            data['popularDishImages'] ??
            data['images'] ??
            data['photos'],
      ),
    ];

    return _uniquePreservingOrder(images);
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

  static String _parseRestaurantType(
    Map<String, dynamic> data, {
    required String name,
    required String address,
    required List<String> reviews,
  }) {
    final explicitType = data['restaurantType'] ??
        data['type'] ??
        data['category'] ??
        data['cuisineType'] ??
        data['foodType'];

    if (explicitType is String && explicitType.trim().isNotEmpty) {
      return _normalizeRestaurantType(explicitType.trim());
    }

    final haystack = '$name $address ${reviews.join(' ')}'.toLowerCase();

    if (_containsAny(haystack, const [
      'bbq',
      'barbecue',
      'grill',
      'ikan bakar',
      'satay',
      'steamboat',
      'seafood grill',
    ])) {
      return 'BBQ & Grill';
    }

    if (_containsAny(haystack, const [
      'cafe',
      'coffee',
      'kopi',
      'kopitiam',
      'espresso',
      'latte',
      'brew',
      'dessert cafe',
    ])) {
      return 'Cafe & Coffee';
    }

    if (_containsAny(haystack, const [
      'western',
      'steak',
      'pasta',
      'lamb chop',
      'chicken chop',
      'fish and chips',
      'burger',
      'pizza',
    ])) {
      return 'Western';
    }

    if (_containsAny(haystack, const [
      'fast food',
      'mcd',
      'mcdonald',
      'kfc',
      'burger king',
      'pizza hut',
      'domino',
      'drive thru',
    ])) {
      return 'Fast Food';
    }

    if (_containsAny(haystack, const [
      'thai',
      'tomyam',
      'tom yam',
      'siam',
      'kerabu mangga',
    ])) {
      return 'Thai';
    }

    if (_containsAny(haystack, const [
      'indian',
      'roti canai',
      'tosai',
      'thosai',
      'naan',
      'tandoori',
      'banana leaf',
      'biryani',
      'mamak',
      'nasi kandar',
    ])) {
      return 'Indian Cuisine';
    }

    if (_containsAny(haystack, const [
      'chinese',
      'dim sum',
      'dimsum',
      'char siew',
      'bak kut teh',
      'wonton',
      'dumpling',
      'yee mee',
      'fried rice',
      'kopitiam',
    ])) {
      return 'Chinese Cuisine';
    }

    if (_containsAny(haystack, const [
      'food court',
      'medan selera',
      'hawker',
      'court',
    ])) {
      return 'Food Court';
    }

    if (_containsAny(haystack, const [
      'warung',
      'gerai',
      'stall',
      'street food',
      'pasar malam',
      'bazaar',
    ])) {
      return 'Street Food';
    }

    return 'Authentic Malay Cuisine';
  }

  static String _normalizeRestaurantType(String value) {
    final normalized = value.trim().toLowerCase();
    final knownTypes = <String, String>{
      'western': 'Western',
      'street food': 'Street Food',
      'food court': 'Food Court',
      'fast food': 'Fast Food',
      'authentic malay cuisine': 'Authentic Malay Cuisine',
      'malay cuisine': 'Authentic Malay Cuisine',
      'chinese cuisine': 'Chinese Cuisine',
      'indian cuisine': 'Indian Cuisine',
      'thai': 'Thai',
      'cafe & coffee': 'Cafe & Coffee',
      'cafe and coffee': 'Cafe & Coffee',
      'bbq & grill': 'BBQ & Grill',
      'bbq and grill': 'BBQ & Grill',
    };

    return knownTypes[normalized] ??
        value
            .split(RegExp(r'\s+'))
            .map((word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
            .join(' ');
  }

  static String _parseHalalStatus(
    Map<String, dynamic> data, {
    required String name,
    required List<String> reviews,
    required String restaurantType,
  }) {
    final explicitValue =
        data['halalStatus'] ?? data['halal'] ?? data['halal_status'];

    if (explicitValue is bool) {
      return explicitValue ? 'Halal' : 'Non-halal';
    }

    if (data['isHalal'] is bool) {
      return (data['isHalal'] as bool) ? 'Halal' : 'Non-halal';
    }

    if (data['nonHalal'] is bool) {
      return (data['nonHalal'] as bool) ? 'Non-halal' : 'Halal';
    }

    if (explicitValue is String && explicitValue.trim().isNotEmpty) {
      final normalized = explicitValue.trim().toLowerCase();
      if (normalized.contains('non')) {
        return 'Non-halal';
      }
      if (normalized.contains('halal')) {
        return 'Halal';
      }
    }

    final haystack = '$name ${reviews.join(' ')}'.toLowerCase();

    if (_containsAny(haystack, const [
      'pork',
      'bacon',
      'lard',
      'char siew',
      'bak kut teh',
      'beer',
      'wine',
      'liquor',
      'alcohol',
    ])) {
      return 'Non-halal';
    }

    if (_containsAny(haystack, const [
      'halal',
      'muslim friendly',
      'mamak',
      'warung',
      'restoran melayu',
      'kedai makan islam',
    ])) {
      return 'Halal';
    }

    if (restaurantType == 'Authentic Malay Cuisine' &&
        _containsAny(haystack, const ['nasi lemak', 'masakan kampung', 'ikan bakar'])) {
      return 'Halal';
    }

    return 'Halal status unavailable';
  }

  static List<String> _parseMenuItems(
    Map<String, dynamic> data, {
    required String name,
    required List<String> reviews,
    required String restaurantType,
  }) {
    final explicitItems = _uniquePreservingOrder([
      ..._toSplitStringList(data['menuItems']),
      ..._toSplitStringList(data['menu']),
      ..._toSplitStringList(data['popularDishes']),
      ..._toSplitStringList(data['signatureDishes']),
    ]);

    if (explicitItems.isNotEmpty) {
      return explicitItems.take(8).toList();
    }

    final haystack = '$name ${reviews.join(' ')}'.toLowerCase();
    final matches = <String>[];

    for (final entry in _popularDishKeywords.entries) {
      if (haystack.contains(entry.key)) {
        matches.add(entry.value);
      }
    }

    if (matches.isNotEmpty) {
      return _uniquePreservingOrder(matches).take(8).toList();
    }

    switch (restaurantType) {
      case 'Cafe & Coffee':
        return const ['Coffee', 'Pastries', 'Desserts'];
      case 'BBQ & Grill':
        return const ['Grilled dishes', 'Seafood', 'BBQ platters'];
      case 'Western':
        return const ['Pasta', 'Steak', 'Burger'];
      case 'Thai':
        return const ['Tom Yam', 'Thai rice dishes', 'Seafood'];
      case 'Indian Cuisine':
        return const ['Roti Canai', 'Biryani', 'Curries'];
      case 'Chinese Cuisine':
        return const ['Noodles', 'Rice dishes', 'Dim Sum'];
      case 'Street Food':
        return const ['Local snacks', 'Mee dishes', 'Rice dishes'];
      case 'Food Court':
        return const ['Mixed local dishes', 'Noodles', 'Rice meals'];
      case 'Fast Food':
        return const ['Burger', 'Fried chicken', 'Combo meals'];
      default:
        return const ['Local rice dishes', 'Noodle dishes', 'Signature specials'];
    }
  }

  static bool _containsAny(String haystack, List<String> keywords) {
    return keywords.any(haystack.contains);
  }

  static List<String> _uniquePreservingOrder(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        continue;
      }
      if (seen.add(normalized.toLowerCase())) {
        result.add(normalized);
      }
    }

    return result;
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

  static const Map<String, String> _popularDishKeywords = {
    'ikan bakar': 'Ikan Bakar',
    'laksa': 'Laksa',
    'nasi lemak': 'Nasi Lemak',
    'nasi campur': 'Nasi Campur',
    'mee goreng': 'Mee Goreng',
    'mee rebus': 'Mee Rebus',
    'char kuey teow': 'Char Kuey Teow',
    'char koay teow': 'Char Kuey Teow',
    'satay': 'Satay',
    'roti canai': 'Roti Canai',
    'tosai': 'Tosai',
    'thosai': 'Tosai',
    'biryani': 'Biryani',
    'naan': 'Naan',
    'tandoori': 'Tandoori',
    'tom yam': 'Tom Yam',
    'tomyam': 'Tom Yam',
    'kerabu': 'Kerabu',
    'belangkas': 'Belangkas',
    'burger': 'Burger',
    'steak': 'Steak',
    'pasta': 'Pasta',
    'pizza': 'Pizza',
    'fried chicken': 'Fried Chicken',
    'seafood': 'Seafood',
    'coffee': 'Coffee',
    'kopi': 'Kopi',
    'dessert': 'Desserts',
    'cake': 'Cake',
  };
}
