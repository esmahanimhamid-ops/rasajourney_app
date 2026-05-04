import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;

  void openMap(double lat, double lng) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng"
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw "Could not open map";
    }
  }

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // IMAGE
          Image.network(
            restaurant.image,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
          ),

          Container(
            height: 250,
            margin: const EdgeInsets.all(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(restaurant.lat, restaurant.lng),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("restaurant"),
                  position: LatLng(restaurant.lat, restaurant.lng),
                  infoWindow: InfoWindow(title: restaurant.name),
                ),
              },
            ),
          ),

          const SizedBox(height: 16),

          // NAME
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              restaurant.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ADDRESS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              restaurant.address,
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "This is one of the famous local dishes in Perlis. "
                  "Definitely will repeat next time!",
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                openMap(restaurant.lat, restaurant.lng);
              },
              icon: const Icon(Icons.map),
              label: const Text("Open in Google Maps"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}