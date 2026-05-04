import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant.dart';
import 'google_places_service.dart';

class RestaurantCleanupResult {
  final int checkedCount;
  final int skippedCount;
  final int deletedCount;
  final List<String> deletedNames;
  final List<String> errors;

  const RestaurantCleanupResult({
    required this.checkedCount,
    required this.skippedCount,
    required this.deletedCount,
    required this.deletedNames,
    required this.errors,
  });
}

class RestaurantCleanupService {
  RestaurantCleanupService({
    FirebaseFirestore? firestore,
    GooglePlacesService? googlePlacesService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _googlePlacesService = googlePlacesService ?? GooglePlacesService();

  final FirebaseFirestore _firestore;
  final GooglePlacesService _googlePlacesService;

  Future<RestaurantCleanupResult> deletePermanentlyClosedRestaurants() async {
    final snapshot = await _firestore.collection('restaurants').get();
    var checkedCount = 0;
    var skippedCount = 0;
    var deletedCount = 0;
    final deletedNames = <String>[];
    final errors = <String>[];

    for (final doc in snapshot.docs) {
      final restaurant = Restaurant.fromMap(doc.data(), id: doc.id);
      final placeId = restaurant.placeId;

      if (placeId == null || placeId.isEmpty) {
        skippedCount++;
        continue;
      }

      checkedCount++;

      try {
        final businessStatus =
            await _googlePlacesService.fetchBusinessStatus(placeId);

        if (businessStatus == 'CLOSED_PERMANENTLY') {
          await doc.reference.delete();
          deletedCount++;
          deletedNames.add(restaurant.name);
        }
      } catch (error) {
        errors.add('${restaurant.name}: $error');
      }
    }

    return RestaurantCleanupResult(
      checkedCount: checkedCount,
      skippedCount: skippedCount,
      deletedCount: deletedCount,
      deletedNames: deletedNames,
      errors: errors,
    );
  }
}
