import 'package:flutter/material.dart';

import '../services/unity_ar_service.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  final UnityARService _unityARService = UnityARService();

  bool _isCheckingAvailability = true;
  bool _isLaunching = false;
  bool _unityAvailable = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final available = await _unityARService.isUnityArAvailable();
    if (!mounted) {
      return;
    }

    setState(() {
      _unityAvailable = available;
      _isCheckingAvailability = false;
      _statusMessage = available
          ? 'Unity AR module detected. Launch the camera to preview the floating restaurant card.'
          : 'Unity AR export is not connected yet. Follow the Unity integration guide in the repo, then this button will launch the Android AR scene.';
    });
  }

  Future<void> _launchUnityAR() async {
    setState(() {
      _isLaunching = true;
      _statusMessage = null;
    });

    try {
      await _unityARService.launch(UnityARPayload.demo);
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Opening Unity AR scene...';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Food Finder'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF3E0),
              Color(0xFFFFE0B2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade50,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.view_in_ar,
                        size: 36,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Unity AR Scene',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Launch a full-screen AR Foundation scene that shows a floating restaurant info card in front of the camera.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PreviewCard(
                      payload: UnityARPayload.demo,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingAvailability || _isLaunching
                            ? null
                            : _launchUnityAR,
                        icon: _isLaunching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(
                          _unityAvailable
                              ? 'Open Unity AR Camera'
                              : 'Try Unity AR Launch',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isCheckingAvailability)
                      const Text('Checking Unity AR module availability...')
                    else if (_statusMessage != null)
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _unityAvailable
                              ? Colors.green.shade700
                              : Colors.brown.shade700,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _ChecklistCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.payload,
  });

  final UnityARPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFA726),
            Color(0xFFF4511E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payload.cuisineLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            payload.restaurantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipText(label: payload.status),
              _ChipText(label: payload.rating),
              _ChipText(label: payload.hours),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            payload.subtitle,
            style: const TextStyle(
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  const _ChipText({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Integration Checklist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text('1. Build the Unity AR Foundation project as an Android Gradle export.'),
          SizedBox(height: 8),
          Text('2. Copy the exported unityLibrary module into the Flutter android folder.'),
          SizedBox(height: 8),
          Text('3. Add the UnityARActivity template and manifest entry from the repo guide.'),
          SizedBox(height: 8),
          Text('4. Relaunch this screen and tap Open Unity AR Camera.'),
        ],
      ),
    );
  }
}
