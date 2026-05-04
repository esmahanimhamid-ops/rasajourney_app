import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiKey = "YOUR_API_KEY";

  static Future<List<dynamic>> getRestaurants() async {
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
            "?location=6.4449,100.2048"
            "&radius=3000"
            "&type=restaurant"
            "&key=$apiKey"
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'];
    } else {
      throw Exception("Failed to load restaurants");
    }
  }
}