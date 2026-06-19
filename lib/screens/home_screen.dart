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
    final size = MediaQuery.sizeOf(context);
    final isSmallPhone = size.width < 380;
    final heroTitleSize = isSmallPhone ? 36.0 : 44.0;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _FoodPromoBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HomeHeader(),
                        const SizedBox(height: 28),
                        _HeroSpotlight(titleSize: heroTitleSize),
                        const SizedBox(height: 22),
                        _PrimaryActions(
                          onExplore: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExploreScreen(),
                            ),
                          ),
                          onJournal: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavouritesScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _PromotionStrip(),
                        const SizedBox(height: 16),
                        const _FeatureGrid(),
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

class _FoodPromoBackground extends StatelessWidget {
  const _FoodPromoBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F3), Color(0xFFFFEEE2), Color(0xFFEFF7EF)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: const [
          _BackgroundDoodle(
            icon: Icons.ramen_dining_rounded,
            alignment: Alignment(-1.04, -0.66),
            size: 132,
            color: Color(0xFFD45720),
          ),
          _BackgroundDoodle(
            icon: Icons.local_dining_rounded,
            alignment: Alignment(1.08, -0.28),
            size: 118,
            color: Color(0xFF2A9D8F),
          ),
          _BackgroundDoodle(
            icon: Icons.set_meal_rounded,
            alignment: Alignment(-1.02, 0.52),
            size: 128,
            color: Color(0xFFF0A43B),
          ),
          _BackgroundDoodle(
            icon: Icons.local_cafe_rounded,
            alignment: Alignment(0.92, 0.9),
            size: 112,
            color: Color(0xFF6A994E),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDoodle extends StatelessWidget {
  const _BackgroundDoodle({
    required this.icon,
    required this.alignment,
    required this.size,
    required this.color,
  });

  final IconData icon;
  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Icon(icon, size: size, color: color.withValues(alpha: 0.08)),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BrandAssetIcon(size: 44, borderRadius: 8),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RasaJourney',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.cocoa,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Perlis food discovery',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.mutedBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const _HeaderBadge(),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2A9D8F).withValues(alpha: 0.18),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF2A9D8F), size: 16),
            SizedBox(width: 5),
            Text(
              'Local',
              style: TextStyle(
                color: Color(0xFF1F7A70),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSpotlight extends StatelessWidget {
  const _HeroSpotlight({required this.titleSize});

  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroVisual(),
        const SizedBox(height: 26),
        const _Eyebrow(label: 'Taste Perlis like a local'),
        const SizedBox(height: 10),
        Text(
          'Discover food worth travelling for.',
          style: TextStyle(
            color: AppTheme.cocoa,
            fontSize: titleSize,
            height: 1.02,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Find hidden restaurants, promote local flavours, save favourite places, and bring signature dishes to life with AR food stories.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.mutedBrown,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.sand),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.clay.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 18,
            top: 18,
            child: _FloatingTag(
              icon: Icons.local_fire_department_rounded,
              label: 'Trending eats',
              color: Color(0xFFD45720),
            ),
          ),
          const Positioned(
            right: 18,
            top: 18,
            child: _FloatingTag(
              icon: Icons.view_in_ar_rounded,
              label: 'AR stories',
              color: Color(0xFF2A9D8F),
            ),
          ),
          const Center(child: _FoodPlateIllustration()),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.cocoa.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.place_rounded, color: Color(0xFFFFD166)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Curated restaurants, local dishes, and personal food trails in one place.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodPlateIllustration extends StatelessWidget {
  const _FoodPlateIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 218,
            height: 218,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE7D8),
              border: Border.all(color: Colors.white, width: 10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Container(
            width: 136,
            height: 136,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFC36A), Color(0xFFD45720)],
              ),
            ),
          ),
          const Icon(Icons.ramen_dining_rounded, color: Colors.white, size: 78),
          const _OrbitIcon(
            icon: Icons.set_meal_rounded,
            alignment: Alignment(-0.94, -0.18),
            color: Color(0xFF2A9D8F),
          ),
          const _OrbitIcon(
            icon: Icons.icecream_rounded,
            alignment: Alignment(0.86, -0.36),
            color: Color(0xFFFFB4A2),
          ),
          const _OrbitIcon(
            icon: Icons.local_cafe_rounded,
            alignment: Alignment(0.58, 0.86),
            color: Color(0xFF6A994E),
          ),
        ],
      ),
    );
  }
}

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({
    required this.icon,
    required this.alignment,
    required this.color,
  });

  final IconData icon;
  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.cocoa,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.onExplore, required this.onJournal});

  final VoidCallback onExplore;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.explore_rounded),
            label: const Text('Explore Food'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.clay,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: onJournal,
          tooltip: 'Open saved food journal',
          icon: const Icon(Icons.bookmark_rounded),
          style: IconButton.styleFrom(
            fixedSize: const Size(54, 54),
            backgroundColor: AppTheme.cocoa.withValues(alpha: 0.08),
            foregroundColor: AppTheme.cocoa,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotionStrip extends StatelessWidget {
  const _PromotionStrip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cocoa,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            _PromoStat(value: '50+', label: 'local spots'),
            _PromoDivider(),
            _PromoStat(value: 'AR', label: 'food labels'),
            _PromoDivider(),
            _PromoStat(value: 'Perlis', label: 'curated trail'),
          ],
        ),
      ),
    );
  }
}

class _PromoStat extends StatelessWidget {
  const _PromoStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoDivider extends StatelessWidget {
  const _PromoDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 390;
        final tiles = const [
          _FeatureTile(
            icon: Icons.storefront_rounded,
            title: 'Promote local restaurants',
            description: 'Spotlight places that travellers should not miss.',
            color: Color(0xFFD45720),
          ),
          _FeatureTile(
            icon: Icons.favorite_rounded,
            title: 'Save personal picks',
            description: 'Build a shortlist for your next makan trip.',
            color: Color(0xFFE76F51),
          ),
          _FeatureTile(
            icon: Icons.rate_review_rounded,
            title: 'Review honestly',
            description: 'Keep useful notes from real food visits.',
            color: Color(0xFF2A9D8F),
          ),
          _FeatureTile(
            icon: Icons.view_in_ar_rounded,
            title: 'Preview food in AR',
            description: 'See dish info as a camera overlay.',
            color: Color(0xFF6A994E),
          ),
        ];

        if (!useTwoColumns) {
          return Column(
            children: [
              for (final tile in tiles) ...[tile, const SizedBox(height: 10)],
            ],
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final tile in tiles)
              SizedBox(width: (constraints.maxWidth - 10) / 2, child: tile),
          ],
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.sand),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.cocoa,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.16,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.mutedBrown,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandAssetIcon extends StatelessWidget {
  const _BrandAssetIcon({required this.size, required this.borderRadius});

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
          return _BrandIconFallback(size: size, borderRadius: borderRadius);
        },
      ),
    );
  }
}

class _BrandIconFallback extends StatelessWidget {
  const _BrandIconFallback({required this.size, required this.borderRadius});

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
          colors: [Color(0xFFFFF4E6), Color(0xFFF8DFC1)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_menu_rounded,
        color: AppTheme.clay,
        size: size * 0.56,
      ),
    );
  }
}
