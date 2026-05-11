import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FoodRecognitionService {
  FoodRecognitionService({http.Client? client})
    : _client = client ?? http.Client();

  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _model = String.fromEnvironment(
    'OPENAI_VISION_MODEL',
    defaultValue: 'gpt-4.1-mini',
  );

  final http.Client _client;

  Future<FoodRecognitionResult> recognizeFood({
    required XFile image,
    required List<String> knownFoodLabels,
  }) async {
    if (_apiKey.isEmpty) {
      throw const FoodRecognitionUnavailableException(
        'AI food recognition needs an OpenAI API key. Run the app with --dart-define=OPENAI_API_KEY=your_key for this prototype.',
      );
    }

    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? _mimeTypeFromPath(image.path);
    final labels = knownFoodLabels.join(', ');
    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'input': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text':
                    'Identify the main food in this image for a Perlis food AR app. '
                    'Choose the best label from this list: $labels, unknown. '
                    'Return only compact JSON with keys: label, confidence, reason. '
                    'Use confidence from 0.0 to 1.0.',
              },
              {
                'type': 'input_image',
                'image_url': 'data:$mimeType;base64,${base64Encode(bytes)}',
                'detail': 'low',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FoodRecognitionUnavailableException(
        'AI recognition failed (${response.statusCode}). ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText = _extractOutputText(decoded);
    final resultJson = _extractJsonObject(outputText);
    final label = (resultJson['label'] as String? ?? 'unknown')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_');
    final confidenceValue = resultJson['confidence'];
    final confidence = confidenceValue is num
        ? confidenceValue.toDouble().clamp(0.0, 1.0)
        : 0.0;

    return FoodRecognitionResult(
      label: label,
      confidence: confidence,
      reason: resultJson['reason'] as String? ?? outputText,
    );
  }

  String _extractOutputText(Map<String, dynamic> response) {
    final directText = response['output_text'];
    if (directText is String && directText.trim().isNotEmpty) {
      return directText.trim();
    }

    final output = response['output'];
    if (output is! List) {
      return '';
    }

    final buffer = StringBuffer();
    for (final item in output) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final part in content) {
        if (part is Map<String, dynamic>) {
          final text = part['text'];
          if (text is String) {
            buffer.write(text);
          }
        }
      }
    }
    return buffer.toString().trim();
  }

  Map<String, dynamic> _extractJsonObject(String text) {
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        return jsonDecode(text.substring(start, end + 1))
            as Map<String, dynamic>;
      }
    }
    return {'label': 'unknown', 'confidence': 0.0, 'reason': text};
  }

  String _mimeTypeFromPath(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

class FoodRecognitionResult {
  const FoodRecognitionResult({
    required this.label,
    required this.confidence,
    required this.reason,
  });

  final String label;
  final double confidence;
  final String reason;
}

class FoodRecognitionUnavailableException implements Exception {
  const FoodRecognitionUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
