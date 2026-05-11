import 'dart:io';

import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../services/food_recognition_service.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  static const _arChannel = MethodChannel('ar_flutter_plugin');

  static const _dishes = [
    ARFoodDish(
      name: 'Laksa Perlis',
      subtitle: 'Tangy rice noodle soup',
      modelAsset: 'primitive://laksa_bowl',
      imageAsset: 'assets/images/laksa_perlis.jpg',
      recognitionLabels: ['laksa_perlis', 'laksa', 'asam_laksa'],
      origin: 'A northern Malaysian laksa style loved in Perlis.',
      description:
          'Laksa Perlis is usually served with thick rice noodles, fish-based gravy, herbs, cucumber, onion, and a bright sour note. It is refreshing, aromatic, and different from creamier curry laksa styles.',
      ingredients: ['Rice noodles', 'Fish gravy', 'Herbs', 'Cucumber'],
      color: Color(0xFFE9552F),
    ),
    ARFoodDish(
      name: 'Nasi Kandar',
      subtitle: 'Rice with layered curries',
      modelAsset: 'primitive://laksa_bowl',
      imageAsset: 'assets/images/nasi_kandar.jpg',
      recognitionLabels: ['nasi_kandar', 'rice_curry', 'mixed_curry_rice'],
      origin: 'A Malaysian Indian Muslim dish strongly associated with Penang.',
      description:
          'Nasi kandar is built around steamed rice, mixed curries, and side dishes such as fried chicken, vegetables, egg, or seafood. The signature moment is kuah campur, where several gravies are poured over the rice.',
      ingredients: [
        'Steamed rice',
        'Mixed curries',
        'Fried chicken',
        'Vegetables',
      ],
      color: Color(0xFF9B5A2E),
    ),
    ARFoodDish(
      name: 'Roti Canai',
      subtitle: 'Flaky flatbread with curry',
      modelAsset: 'primitive://laksa_bowl',
      imageAsset: 'assets/images/nasi_kandar.jpg',
      recognitionLabels: ['roti_canai', 'roti', 'flatbread_curry'],
      origin: 'A Malaysian Indian flatbread often found in breakfast stalls.',
      description:
          'Roti canai is stretched, folded, griddled until flaky, and usually served with dhal, curry, or sambal. It is a common comfort food across Perlis restaurants and stalls.',
      ingredients: ['Flatbread', 'Dhal', 'Curry', 'Sambal'],
      color: Color(0xFFC47C22),
    ),
    ARFoodDish(
      name: 'Satay',
      subtitle: 'Grilled skewers with peanut sauce',
      modelAsset: 'primitive://laksa_bowl',
      imageAsset: 'assets/images/nasi_kandar.jpg',
      recognitionLabels: ['satay', 'sate', 'grilled_skewers'],
      origin: 'A popular grilled skewer dish served across Malaysia.',
      description:
          'Satay is marinated meat grilled over heat and served with peanut sauce, cucumber, onion, and compressed rice. It is easy to recognize from its skewers and charred edges.',
      ingredients: ['Skewered meat', 'Peanut sauce', 'Cucumber', 'Onion'],
      color: Color(0xFF8D5B2F),
    ),
    ARFoodDish(
      name: 'Mee Rebus',
      subtitle: 'Noodles in rich sweet potato gravy',
      modelAsset: 'primitive://laksa_bowl',
      imageAsset: 'assets/images/laksa_perlis.jpg',
      recognitionLabels: ['mee_rebus', 'noodle_gravy', 'yellow_noodles'],
      origin: 'A noodle dish with a thick, savoury gravy found in many stalls.',
      description:
          'Mee rebus uses yellow noodles with a rich gravy, often topped with egg, fried shallots, herbs, chilli, and lime. The sauce is thicker and sweeter than laksa gravy.',
      ingredients: ['Yellow noodles', 'Gravy', 'Egg', 'Fried shallots'],
      color: Color(0xFFD69B2D),
    ),
  ];

  final _imagePicker = ImagePicker();
  final _foodRecognitionService = FoodRecognitionService();
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARNode? _currentNode;
  int _selectedDishIndex = 0;
  bool _arReady = false;
  bool _arStarted = false;
  bool _recognizedByAi = false;
  bool _isRecognizingFood = false;
  bool _isPlacing = false;
  bool _isCheckingSupport = false;
  FoodRecognitionResult? _recognitionResult;
  String _statusMessage =
      'Use AI food recognition first, then open AR to preview the matching 3D food.';

  ARFoodDish get _selectedDish => _dishes[_selectedDishIndex];

  bool get _supportsAR => Platform.isAndroid || Platform.isIOS;

  @override
  void dispose() {
    try {
      _arSessionManager?.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _startAR() async {
    if (_isCheckingSupport) {
      return;
    }

    setState(() {
      _isCheckingSupport = true;
      _statusMessage = 'Checking AR support on this device...';
    });

    final supported = await _isDeviceReadyForAR();
    if (!mounted) {
      return;
    }

    final unavailableMessage = await _buildARUnavailableMessage();
    if (!mounted) {
      return;
    }

    setState(() {
      _isCheckingSupport = false;
      _arStarted = supported;
      _statusMessage = supported
          ? _recognizedByAi
                ? 'Starting AR camera for ${_selectedDish.name}...'
                : 'Starting AR camera. Point it at the registered food picture.'
          : unavailableMessage;
    });
  }

  Future<bool> _isDeviceReadyForAR() async {
    if (!_supportsAR) {
      return false;
    }

    if (Platform.isIOS) {
      return true;
    }

    try {
      return await _arChannel.invokeMethod<bool>('isArCoreSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String> _buildARUnavailableMessage() async {
    if (Platform.isIOS) {
      return 'AR could not start on this iPhone or iPad. You can still read the food preview here.';
    }

    try {
      final availability =
          await _arChannel.invokeMethod<String>('getArCoreAvailability') ??
          'UNKNOWN';
      if (availability.contains('NOT_INSTALLED')) {
        return 'Google Play Services for AR is not installed on this phone. Install it from Play Store if your device supports ARCore.';
      }
      if (availability.contains('UNSUPPORTED')) {
        return 'This phone does not support ARCore, so the AR camera cannot open. You can still read the food preview here.';
      }
      if (availability.contains('TOO_OLD')) {
        return 'Google Play Services for AR needs an update before the AR camera can open.';
      }
    } catch (_) {}

    return 'This device is not ready for ARCore. You can still read the food preview here.';
  }

  Future<void> _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    try {
      _arSessionManager = sessionManager;
      _arObjectManager = objectManager;

      await _arSessionManager?.onInitialize(
        showAnimatedGuide: false,
        showFeaturePoints: false,
        showPlanes: false,
        imageTrackingAssetPath: _recognizedByAi
            ? null
            : _selectedDish.imageAsset,
        handleTaps: true,
        handlePans: true,
        handleRotation: true,
      );
      await _arObjectManager?.onInitialize();

      _arSessionManager?.onPlaneOrPointTap = _handlePlaneTap;

      if (!mounted) {
        return;
      }

      setState(() {
        _arReady = true;
        _statusMessage = _recognizedByAi
            ? 'AI recognized ${_selectedDish.name}. Placing the 3D preview in front of you.'
            : 'Scan the exact ${_selectedDish.name} picture shown in this app or on your menu. Keep it flat and well lit.';
      });

      if (_recognizedByAi) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await _placeDishInFrontOfCamera();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _arReady = false;
        _arStarted = false;
        _isPlacing = false;
        _statusMessage =
            'AR could not start on this device. You can still view the food information here.';
      });
    }
  }

  Future<void> _handlePlaneTap(List<ARHitTestResult> hits) async {
    if (hits.isEmpty || _isPlacing) {
      return;
    }

    final hit = hits.first;
    await _placeDish(transform: hit.worldTransform);
  }

  Future<void> _placeDishInFrontOfCamera() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final cameraPose = await _arSessionManager?.getCameraPose();
      if (cameraPose != null) {
        final position = cameraPose.transform3(vector.Vector3(0, -0.08, -0.75));
        await _placeDish(position: position);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage =
          'Camera is ready, but I could not place the 3D food yet. Move the phone slowly and tap reset.';
    });
  }

  Future<void> _placeDish({
    vector.Vector3? position,
    Matrix4? transform,
  }) async {
    final objectManager = _arObjectManager;
    if (objectManager == null || _isPlacing) {
      return;
    }

    setState(() {
      _isPlacing = true;
      _statusMessage = 'Placing ${_selectedDish.name} in AR...';
    });

    final previousNode = _currentNode;
    if (previousNode != null) {
      await objectManager.removeNode(previousNode);
    }

    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: _selectedDish.modelAsset,
      name: _selectedDish.name,
      position: position,
      transformation: transform,
      scale: vector.Vector3.all(0.35),
    );

    final added = await objectManager.addNode(node) ?? false;
    if (!mounted) {
      return;
    }

    setState(() {
      _currentNode = added ? node : null;
      _isPlacing = false;
      _statusMessage = added
          ? '${_selectedDish.name} is placed. Drag or twist the 3D bowl to move or rotate it.'
          : 'Could not place the food model. Try again in brighter light.';
    });
  }

  Future<void> _recognizeFood(ImageSource source) async {
    if (_isRecognizingFood) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image == null) {
        return;
      }

      setState(() {
        _isRecognizingFood = true;
        _statusMessage = 'AI is checking the food photo...';
      });

      final knownLabels = _dishes
          .expand((dish) => dish.recognitionLabels)
          .toSet()
          .toList(growable: false);
      final result = await _foodRecognitionService.recognizeFood(
        image: image,
        knownFoodLabels: knownLabels,
      );
      final matchedIndex = _dishIndexForRecognitionLabel(result.label);

      if (!mounted) {
        return;
      }

      if (matchedIndex == null || result.confidence < 0.35) {
        setState(() {
          _isRecognizingFood = false;
          _recognizedByAi = false;
          _recognitionResult = result;
          _statusMessage =
              'AI could not confidently match this food yet. Try a clearer close-up photo, or add this food to the app dataset.';
        });
        return;
      }

      setState(() {
        _selectedDishIndex = matchedIndex;
        _recognizedByAi = true;
        _recognitionResult = result;
        _isRecognizingFood = false;
        _statusMessage =
            'AI thinks this is ${_dishes[matchedIndex].name} (${(result.confidence * 100).round()}%). Start AR to view the 3D preview.';
      });
    } on FoodRecognitionUnavailableException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecognizingFood = false;
        _recognizedByAi = false;
        _statusMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecognizingFood = false;
        _recognizedByAi = false;
        _statusMessage = 'AI food recognition failed. $error';
      });
    }
  }

  int? _dishIndexForRecognitionLabel(String label) {
    final normalized = label.toLowerCase().trim().replaceAll(' ', '_');
    for (var i = 0; i < _dishes.length; i++) {
      if (_dishes[i].recognitionLabels.contains(normalized)) {
        return i;
      }
    }
    return null;
  }

  Future<void> _selectDish(int index) async {
    setState(() {
      _selectedDishIndex = index;
      _recognizedByAi = false;
      _recognitionResult = null;
      _statusMessage = _arReady
          ? 'Selected ${_dishes[index].name}. Restart AR to track that menu picture.'
          : 'Selected ${_dishes[index].name}. You can use registered image tracking, or recognize a food photo first.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsAR) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AR Food Preview'),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: _FallbackFoodPreview(
          dishes: _dishes,
          selectedIndex: _selectedDishIndex,
          onSelected: (index) => setState(() => _selectedDishIndex = index),
          onRecognizeFromCamera: () => _recognizeFood(ImageSource.camera),
          onRecognizeFromGallery: () => _recognizeFood(ImageSource.gallery),
          isRecognizingFood: _isRecognizingFood,
          recognitionResult: _recognitionResult,
          statusMessage:
              'AR camera works on Android or iOS devices. Here is the food preview and info while you test on this platform.',
        ),
      );
    }

    if (!_arStarted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AR Food Preview'),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: _FallbackFoodPreview(
          dishes: _dishes,
          selectedIndex: _selectedDishIndex,
          onSelected: (index) => setState(() => _selectedDishIndex = index),
          onStartAR: _startAR,
          onRecognizeFromCamera: () => _recognizeFood(ImageSource.camera),
          onRecognizeFromGallery: () => _recognizeFood(ImageSource.gallery),
          isCheckingSupport: _isCheckingSupport,
          isRecognizingFood: _isRecognizingFood,
          recognitionResult: _recognitionResult,
          statusMessage: _statusMessage,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.none,
            permissionPromptDescription:
                'Camera access is needed to show food in augmented reality.',
            permissionPromptButtonText: 'Allow camera',
          ),
          SafeArea(
            child: Column(
              children: [
                _TopARBar(
                  statusMessage: _statusMessage,
                  isPlacing: _isPlacing,
                  onReset: _recognizedByAi ? _placeDishInFrontOfCamera : null,
                ),
                const Spacer(),
                _DishSelector(
                  dishes: _dishes,
                  selectedIndex: _selectedDishIndex,
                  onSelected: _selectDish,
                ),
                _DishInfoSheet(dish: _selectedDish),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ARFoodDish {
  final String name;
  final String subtitle;
  final String modelAsset;
  final String imageAsset;
  final List<String> recognitionLabels;
  final String origin;
  final String description;
  final List<String> ingredients;
  final Color color;

  const ARFoodDish({
    required this.name,
    required this.subtitle,
    required this.modelAsset,
    required this.imageAsset,
    required this.recognitionLabels,
    required this.origin,
    required this.description,
    required this.ingredients,
    required this.color,
  });
}

class _TopARBar extends StatelessWidget {
  const _TopARBar({
    required this.statusMessage,
    required this.isPlacing,
    required this.onReset,
  });

  final String statusMessage;
  final bool isPlacing;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (isPlacing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        Icons.view_in_ar,
                        color: Colors.white,
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: onReset,
              tooltip: 'Reset 3D model',
              icon: const Icon(Icons.center_focus_strong),
            ),
          ],
        ],
      ),
    );
  }
}

class _DishSelector extends StatelessWidget {
  const _DishSelector({
    required this.dishes,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ARFoodDish> dishes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dishes.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final dish = dishes[index];
          final isSelected = index == selectedIndex;

          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: CircleAvatar(backgroundImage: AssetImage(dish.imageAsset)),
            label: Text(dish.name),
            onSelected: (_) => onSelected(index),
            selectedColor: dish.color.withValues(alpha: 0.24),
            backgroundColor: Colors.white.withValues(alpha: 0.88),
            side: BorderSide(
              color: isSelected ? dish.color : Colors.transparent,
              width: 1.5,
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: isSelected ? dish.color : Colors.black87,
            ),
          );
        },
      ),
    );
  }
}

class _DishInfoSheet extends StatelessWidget {
  const _DishInfoSheet({required this.dish});

  final ARFoodDish dish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    dish.imageAsset,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dish.subtitle,
                        style: TextStyle(
                          color: dish.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              dish.origin,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              dish.description,
              style: TextStyle(color: Colors.grey.shade800, height: 1.45),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dish.ingredients
                  .map(
                    (ingredient) => Chip(
                      label: Text(ingredient),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: dish.color.withValues(alpha: 0.12),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackFoodPreview extends StatelessWidget {
  const _FallbackFoodPreview({
    required this.dishes,
    required this.selectedIndex,
    required this.onSelected,
    required this.statusMessage,
    required this.onRecognizeFromCamera,
    required this.onRecognizeFromGallery,
    required this.isRecognizingFood,
    required this.recognitionResult,
    this.onStartAR,
    this.isCheckingSupport = false,
  });

  final List<ARFoodDish> dishes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String statusMessage;
  final VoidCallback onRecognizeFromCamera;
  final VoidCallback onRecognizeFromGallery;
  final bool isRecognizingFood;
  final FoodRecognitionResult? recognitionResult;
  final VoidCallback? onStartAR;
  final bool isCheckingSupport;

  @override
  Widget build(BuildContext context) {
    final dish = dishes[selectedIndex];

    return Container(
      color: const Color(0xFFFFF3E0),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              statusMessage,
              style: TextStyle(color: Colors.brown.shade700, height: 1.4),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                dish.imageAsset,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            _DishSelector(
              dishes: dishes,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
            const SizedBox(height: 10),
            _FoodRecognitionActions(
              isRecognizingFood: isRecognizingFood,
              onCamera: onRecognizeFromCamera,
              onGallery: onRecognizeFromGallery,
            ),
            if (recognitionResult != null) ...[
              const SizedBox(height: 10),
              _RecognitionResultCard(result: recognitionResult!),
            ],
            if (onStartAR != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isCheckingSupport ? null : onStartAR,
                  icon: isCheckingSupport
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.view_in_ar),
                  label: Text(
                    isCheckingSupport
                        ? 'Checking AR support...'
                        : 'Start AR Camera',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _DishInfoSheet(dish: dish),
          ],
        ),
      ),
    );
  }
}

class _FoodRecognitionActions extends StatelessWidget {
  const _FoodRecognitionActions({
    required this.isRecognizingFood,
    required this.onCamera,
    required this.onGallery,
  });

  final bool isRecognizingFood;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    if (isRecognizingFood) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Recognize Food'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose Photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecognitionResultCard extends StatelessWidget {
  const _RecognitionResultCard({required this.result});

  final FoodRecognitionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI result: ${result.label.replaceAll('_', ' ')} '
              '(${(result.confidence * 100).round()}%).',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
