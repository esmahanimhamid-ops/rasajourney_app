import 'dart:io';
import 'dart:math' as math;

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
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARNode? _currentNode;
  final int _selectedDishIndex = 0;
  bool _arReady = false;
  bool _arStarted = false;
  bool _isRecognizingFood = false;
  bool _isPlacing = false;
  bool _isCheckingSupport = false;
  bool _showFoodPreview = true;
  double _previewYaw = -0.25;
  double _previewPitch = 0.12;
  String? _scannedFoodImagePath;
  String _statusMessage =
      'Tekan camera, scan gambar makanan, lepas tu gambar tu terus keluar dalam 3D.';

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
      _showFoodPreview = supported;
      _statusMessage = supported
          ? 'Opening AR camera. Your scanned image will appear as a 3D preview.'
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
        showPlanes: true,
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
        _showFoodPreview = true;
        _statusMessage = _scannedFoodImagePath == null
            ? 'Tap the camera button to scan food. The 3D preview will appear here.'
            : 'Image scanned. Drag the 3D preview to rotate it.';
      });

      await Future<void>.delayed(const Duration(milliseconds: 700));
      await _placeDishInFrontOfCamera();
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
          'Camera is ready, but I could not place the 3D food yet. Move the phone slowly around the table, then tap reset.';
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
      _statusMessage = 'Preparing 3D food preview...';
    });

    final previousNode = _currentNode;
    if (previousNode != null) {
      await objectManager.removeNode(previousNode);
    }

    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: _selectedDish.modelAsset,
      name: 'Scanned food preview',
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
      _statusMessage = _scannedFoodImagePath == null
          ? 'Tap the camera button to scan food.'
          : '3D preview is ready. Drag it left, right, up, or down to rotate.';
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
        _scannedFoodImagePath = image.path;
        _showFoodPreview = true;
        _statusMessage = 'Image scanned. Opening 3D AR preview...';
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecognizingFood = false;
        _showFoodPreview = true;
        _statusMessage = _supportsAR
            ? 'Image scanned. Showing it in 3D AR now.'
            : 'Image scanned. Showing it as a 3D preview.';
      });

      if (_supportsAR && !_arStarted) {
        await _startAR();
        return;
      }

      if (_arReady) {
        await _placeDishInFrontOfCamera();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecognizingFood = false;
        _statusMessage = 'Camera scan failed. $error';
      });
    }
  }

  void _rotatePreview(DragUpdateDetails details) {
    setState(() {
      _previewYaw += details.delta.dx * 0.015;
      _previewPitch = (_previewPitch - details.delta.dy * 0.015).clamp(
        -0.8,
        0.8,
      );
    });
  }

  void _resetPreviewRotation() {
    setState(() {
      _previewYaw = -0.25;
      _previewPitch = 0.12;
      _showFoodPreview = true;
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
          scannedImagePath: _scannedFoodImagePath,
          onRecognizeFromCamera: () => _recognizeFood(ImageSource.camera),
          onRecognizeFromGallery: () => _recognizeFood(ImageSource.gallery),
          isRecognizingFood: _isRecognizingFood,
          statusMessage:
              'Tekan camera untuk scan gambar makanan. AR camera works on Android or iOS devices.',
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
          scannedImagePath: _scannedFoodImagePath,
          onStartAR: _startAR,
          onRecognizeFromCamera: () => _recognizeFood(ImageSource.camera),
          onRecognizeFromGallery: () => _recognizeFood(ImageSource.gallery),
          isCheckingSupport: _isCheckingSupport,
          isRecognizingFood: _isRecognizingFood,
          statusMessage: _statusMessage,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
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
                  onReset: _placeDishInFrontOfCamera,
                  onShowPreview: () => setState(() => _showFoodPreview = true),
                ),
                const Spacer(),
                _ARCameraActions(
                  isScanning: _isRecognizingFood,
                  onCamera: () => _recognizeFood(ImageSource.camera),
                  onGallery: () => _recognizeFood(ImageSource.gallery),
                ),
              ],
            ),
          ),
          if (_showFoodPreview)
            _Food3DPreviewPopup(
              dish: _selectedDish,
              scannedImagePath: _scannedFoodImagePath,
              yaw: _previewYaw,
              pitch: _previewPitch,
              onRotate: _rotatePreview,
              onReset: _resetPreviewRotation,
              onClose: () => setState(() => _showFoodPreview = false),
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
    required this.onShowPreview,
  });

  final String statusMessage;
  final bool isPlacing;
  final VoidCallback? onReset;
  final VoidCallback onShowPreview;

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
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onShowPreview,
            tooltip: 'Show 3D food',
            icon: const Icon(Icons.threed_rotation),
          ),
        ],
      ),
    );
  }
}

class _Food3DPreviewPopup extends StatelessWidget {
  const _Food3DPreviewPopup({
    required this.dish,
    required this.scannedImagePath,
    required this.yaw,
    required this.pitch,
    required this.onRotate,
    required this.onReset,
    required this.onClose,
  });

  final ARFoodDish dish;
  final String? scannedImagePath;
  final double yaw;
  final double pitch;
  final GestureDragUpdateCallback onRotate;
  final VoidCallback onReset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: IgnorePointer(
          ignoring: false,
          child: Align(
            alignment: const Alignment(0, -0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 390),
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '3D Laksa Bowl',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  scannedImagePath == null
                                      ? 'Scan a food image first'
                                      : 'Drag to rotate the bowl',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onReset,
                            tooltip: 'Reset rotation',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh),
                          ),
                          IconButton(
                            onPressed: onClose,
                            tooltip: 'Close 3D food',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onPanUpdate: onRotate,
                        child: SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0012)
                                ..rotateX(pitch)
                                ..rotateY(yaw),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CustomPaint(
                                    painter: _FoodBowl3DPainter(
                                      dishColor: dish.color,
                                      yaw: yaw,
                                      pitch: pitch,
                                      hasScannedImage: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodBowl3DPainter extends CustomPainter {
  const _FoodBowl3DPainter({
    required this.dishColor,
    required this.yaw,
    required this.pitch,
    required this.hasScannedImage,
  });

  final Color dishColor;
  final double yaw;
  final double pitch;
  final bool hasScannedImage;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.53);
    final turn = math.sin(yaw);
    final tilt = 1 - (pitch.abs() * 0.42);
    final bowlWidth = size.width * (hasScannedImage ? 0.78 : 0.68);
    final bowlHeight = size.height * (hasScannedImage ? 0.42 : 0.34) * tilt;
    final rimRect = Rect.fromCenter(
      center: center,
      width: bowlWidth,
      height: bowlHeight,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + bowlHeight * 0.54),
        width: bowlWidth * 0.86,
        height: bowlHeight * 0.42,
      ),
      shadowPaint,
    );

    final bowlBody = Path()
      ..moveTo(rimRect.left + bowlWidth * 0.06, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy + bowlHeight * 1.08,
        rimRect.right - bowlWidth * 0.06,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + bowlHeight * 0.35,
        rimRect.left + bowlWidth * 0.06,
        center.dy,
      )
      ..close();
    canvas.drawPath(
      bowlBody,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF1D3),
            Color.lerp(const Color(0xFFD7A86E), dishColor, 0.24)!,
            const Color(0xFF8F5B32),
          ],
        ).createShader(bowlBody.getBounds()),
    );

    canvas.drawOval(
      rimRect.inflate(5),
      Paint()
        ..color = const Color(0xFFFFF5DF)
        ..style = PaintingStyle.fill,
    );
    if (hasScannedImage) {
      canvas.drawOval(
        rimRect.inflate(13),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.92),
              const Color(0xFFE9D1A7),
              const Color(0xFF8F6B45),
            ],
          ).createShader(rimRect.inflate(13)),
      );
      canvas.drawOval(
        rimRect.inflate(5),
        Paint()..color = const Color(0xFFFFF7E8),
      );
      canvas.drawArc(
        rimRect.inflate(10),
        math.pi * (1.03 + turn * 0.1),
        math.pi * 0.5,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      return;
    }
    canvas.drawOval(
      rimRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            dishColor.withValues(alpha: 0.95),
            const Color(0xFFE8792E),
            const Color(0xFFFFC55C),
          ],
        ).createShader(rimRect),
    );
    canvas.drawOval(
      rimRect.deflate(12),
      Paint()..color = const Color(0xFFFFD36D).withValues(alpha: 0.76),
    );

    final noodlePaint = Paint()
      ..color = const Color(0xFFFFF1B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final offset = (i - 3) * 17.0 + turn * 14;
      final y = center.dy - bowlHeight * 0.05 + (i.isEven ? 7 : -5);
      final path = Path()
        ..moveTo(center.dx - 78 + offset, y)
        ..cubicTo(
          center.dx - 42 + offset,
          y - 24,
          center.dx + 12 + offset,
          y + 24,
          center.dx + 68 + offset,
          y - 2,
        );
      canvas.drawPath(path, noodlePaint);
    }

    final herbPaint = Paint()..color = const Color(0xFF2F8F3A);
    final chilliPaint = Paint()..color = const Color(0xFFD8231F);
    for (var i = 0; i < 5; i++) {
      final angle = yaw + i * 1.22;
      final itemCenter = Offset(
        center.dx + math.cos(angle) * bowlWidth * 0.22,
        center.dy + math.sin(angle) * bowlHeight * 0.22,
      );
      canvas.save();
      canvas.translate(itemCenter.dx, itemCenter.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-18, -5, 36, 10),
          const Radius.circular(6),
        ),
        i.isEven ? herbPaint : chilliPaint,
      );
      canvas.restore();
    }

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      rimRect.deflate(8),
      math.pi * (1.08 + turn * 0.12),
      math.pi * 0.42,
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FoodBowl3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.dishColor != dishColor ||
        oldDelegate.hasScannedImage != hasScannedImage;
  }
}

class _FallbackFoodPreview extends StatelessWidget {
  const _FallbackFoodPreview({
    required this.scannedImagePath,
    required this.statusMessage,
    required this.onRecognizeFromCamera,
    required this.onRecognizeFromGallery,
    required this.isRecognizingFood,
    this.onStartAR,
    this.isCheckingSupport = false,
  });

  final String? scannedImagePath;
  final String statusMessage;
  final VoidCallback onRecognizeFromCamera;
  final VoidCallback onRecognizeFromGallery;
  final bool isRecognizingFood;
  final VoidCallback? onStartAR;
  final bool isCheckingSupport;

  @override
  Widget build(BuildContext context) {
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
            _InlineScannedPreview(scannedImagePath: scannedImagePath),
            const SizedBox(height: 10),
            _FoodRecognitionActions(
              isRecognizingFood: isRecognizingFood,
              onCamera: onRecognizeFromCamera,
              onGallery: onRecognizeFromGallery,
            ),
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
          ],
        ),
      ),
    );
  }
}

class _InlineScannedPreview extends StatelessWidget {
  const _InlineScannedPreview({required this.scannedImagePath});

  final String? scannedImagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.14)),
        ),
        child: Center(
          child: scannedImagePath == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.deepOrange.shade300,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Scan food image',
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(0.76)
                    ..rotateY(-0.24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.file(
                      File(scannedImagePath!),
                      width: 210,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ARCameraActions extends StatelessWidget {
  const _ARCameraActions({
    required this.isScanning,
    required this.onCamera,
    required this.onGallery,
  });

  final bool isScanning;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: isScanning ? null : onCamera,
              icon: isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(isScanning ? 'Scanning...' : 'Scan Image'),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: isScanning ? null : onGallery,
            tooltip: 'Choose image',
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
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
            label: const Text('Scan Image'),
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
