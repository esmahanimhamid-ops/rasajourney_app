import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'explore_screen.dart';
import 'favourites_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _brandIconAsset =
      'assets/images/branding/rasajourney_app_icon.png';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompactHeight = screenSize.height < 760;
    final headlineFontSize = screenSize.width < 380 ? 32.0 : 38.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/laksa_perlis.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.76),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.8),
                  radius: 1.1,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _BrandAssetIcon(size: 30, borderRadius: 12),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'RasaJourney Perlis',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: isCompactHeight ? 56 : constraints.maxHeight * 0.22,
                        ),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              _brandIconAsset,
                              width: screenSize.width < 380 ? 96 : 112,
                              height: screenSize.width < 380 ? 96 : 112,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                final size =
                                    screenSize.width < 380 ? 96.0 : 112.0;
                                return _BrandIconFallback(
                                  size: size,
                                  borderRadius: 28,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Turn local food into memories you want to revisit.',
                          style: TextStyle(
                            fontSize: headlineFontSize,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Discover hidden restaurants, save the ones that feel special, and build a personal trail of flavours across Perlis.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.84),
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MoodChip(
                              icon: Icons.favorite_rounded,
                              label: 'Save meaningful spots',
                            ),
                            _MoodChip(
                              icon: Icons.rate_review_rounded,
                              label: 'Capture honest reviews',
                            ),
                            _MoodChip(
                              icon: Icons.view_in_ar_rounded,
                              label: 'See food stories in AR',
                            ),
                          ],
                        ),
                        SizedBox(height: isCompactHeight ? 20 : 26),
                        Container(
                          padding: EdgeInsets.all(isCompactHeight ? 18 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Make the app feel like your own travel diary.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explore first, then keep the restaurants that deserve a second visit inside your journal.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.82),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ExploreScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.explore_outlined),
                                    label: const Text('Start Exploring'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.clay,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const FavouritesScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.bookmark_outline_rounded,
                                    ),
                                    label: const Text('Open My Journal'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.35),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandAssetIcon extends StatelessWidget {
  const _BrandAssetIcon({
    required this.size,
    required this.borderRadius,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        HomeScreen._brandIconAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _BrandIconFallback(
            size: size,
            borderRadius: borderRadius,
          );
        },
      ),
    );
  }
}

class _BrandIconFallback extends StatelessWidget {
  const _BrandIconFallback({
    required this.size,
    required this.borderRadius,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF4E6),
            Color(0xFFF8DFC1),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_rounded,
        color: AppTheme.clay,
        size: size * 0.56,
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final maxChipWidth = MediaQuery.sizeOf(context).width - 72;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
