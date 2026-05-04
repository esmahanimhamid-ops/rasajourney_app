import 'dart:io';

import 'package:flutter/services.dart';

class UnityARPayload {
  final String restaurantName;
  final String cuisineLabel;
  final String status;
  final String hours;
  final String rating;
  final String subtitle;

  const UnityARPayload({
    required this.restaurantName,
    required this.cuisineLabel,
    required this.status,
    required this.hours,
    required this.rating,
    required this.subtitle,
  });

  Map<String, String> toMap() {
    return {
      'restaurantName': restaurantName,
      'cuisineLabel': cuisineLabel,
      'status': status,
      'hours': hours,
      'rating': rating,
      'subtitle': subtitle,
    };
  }

  static const demo = UnityARPayload(
    restaurantName: 'RasaJourney Food Spot',
    cuisineLabel: 'Perlis Food Pick',
    status: 'Open now',
    hours: '10:00 AM - 10:00 PM',
    rating: '4.6 / 5',
    subtitle: 'Point your camera to preview a floating restaurant info card.',
  );
}

class UnityARService {
  static const MethodChannel _channel = MethodChannel('rasajourney/unity_ar');

  Future<bool> isUnityArAvailable() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final available =
          await _channel.invokeMethod<bool>('isUnityArAvailable');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> launch(UnityARPayload payload) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Unity AR launch is only configured for Android.');
    }

    await _channel.invokeMethod<void>('launchUnityAr', payload.toMap());
  }
}
