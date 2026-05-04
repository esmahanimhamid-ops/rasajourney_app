import 'package:flutter/services.dart';

class PlatformConfigService {
  static const MethodChannel _channel = MethodChannel('rasajourney/config');
  static String? _mapsApiKeyCache;

  static Future<String?> getMapsApiKey() async {
    if (_mapsApiKeyCache != null && _mapsApiKeyCache!.isNotEmpty) {
      return _mapsApiKeyCache;
    }

    try {
      final apiKey = await _channel.invokeMethod<String>('getMapsApiKey');
      if (apiKey != null && apiKey.isNotEmpty) {
        _mapsApiKeyCache = apiKey;
      }
      return _mapsApiKeyCache;
    } catch (_) {
      return null;
    }
  }
}
