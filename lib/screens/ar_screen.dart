
import 'package:flutter/material.dart';
// import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});
  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
//  ARSessionManager? arSessionManager;
  final _reviewController = TextEditingController();
  double _rating = 3.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // AR view fills screen
      //    ARView(
      //      onARViewCreated: (sessionManager, objectManager, anchorManager, locationManager) {
      //        arSessionManager = sessionManager;
      //        arSessionManager!.onInitialize(
      //          showAnimatedGuide: true,
      //          showFeaturePoints: false,
      //          showWorldOrigin: false,
      //        );
      //      },
      //    ),
          // Review panel at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Share your experience',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setState(() => _rating = i + 1.0),
                      );
                    }),
                  ),
                  TextField(
                    controller: _reviewController,
                    decoration: const InputDecoration(
                      hintText: 'Write your review here...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48)),
                    child: const Text('Submit Review'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
  //  await FirebaseFirestore.instance.collection('reviews').add({
  //    'text': _reviewController.text,
  //    'rating': _rating,
  //    'timestamp': FieldValue.serverTimestamp(),
      // Add restaurantId once you have auth/restaurant selection
  //  });
    _reviewController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!')));
  }
}