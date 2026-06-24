import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/main_nav_scope.dart';
import '../widgets/smart_back_button.dart';
import 'explore_screen.dart';
import 'favourites_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _brandIconAsset =
      'assets/images/branding/rasajourney_app_icon.png';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 720 ? 36.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F1),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                28,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HomeHeader(),
                        const SizedBox(height: 22),
                        _ProfessionalHero(
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
                        const SizedBox(height: 18),
                        const _DecisionPanel(),
                        const SizedBox(height: 18),
                        const _JourneyPreview(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final navScope = MainNavScope.maybeOf(context);

    return Row(
      children: [
        SmartBackButton(fallback: navScope?.goHome),
        const SizedBox(width: 4),
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
              SizedBox(height: 2),
              Text(
                'Curated Perlis food discovery',
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
        const _TrustBadge(),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF226B5F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF226B5F).withValues(alpha: 0.16),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF226B5F), size: 16),
          SizedBox(width: 5),
          Text(
            'Local',
            style: TextStyle(
              color: Color(0xFF226B5F),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalHero extends StatelessWidget {
  const _ProfessionalHero({required this.onExplore, required this.onJournal});

  final VoidCallback onExplore;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 380 ? 32.0 : 40.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final image = _HeroImageStack(compact: !wide);
        final copy = _HeroCopy(
          titleSize: titleSize,
          onExplore: onExplore,
          onJournal: onJournal,
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [image, const SizedBox(height: 20), copy],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 6, child: copy),
            const SizedBox(width: 28),
            Expanded(flex: 5, child: image),
          ],
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.titleSize,
    required this.onExplore,
    required this.onJournal,
  });

  final double titleSize;
  final VoidCallback onExplore;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(label: 'Perlis gastronomy guide'),
        const SizedBox(height: 12),
        Text(
          'Plan a food trip that feels local from the first stop.',
          style: TextStyle(
            color: AppTheme.cocoa,
            fontSize: titleSize,
            height: 1.06,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Explore trusted restaurants, signature dishes, saved favourites, and AR food stories designed for confident decisions before you arrive.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF6D584E),
            fontSize: 16,
            height: 1.48,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        _PrimaryActions(onExplore: onExplore, onJournal: onJournal),
        const SizedBox(height: 18),
        const _MetricRow(),
      ],
    );
  }
}

class _HeroImageStack extends StatelessWidget {
  const _HeroImageStack({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: compact ? 1.1 : 0.95,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/laksa_perlis.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.52),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  _SignalIcon(
                    icon: Icons.restaurant_menu_rounded,
                    color: AppTheme.clay,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laksa Perlis',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.cocoa,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'A local flavour cue before the map opens.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.mutedBrown,
                            fontWeight: FontWeight.w700,
                            height: 1.28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _ImagePill(
              icon: Icons.auto_awesome_rounded,
              label: 'Curated',
              color: AppTheme.amber,
            ),
          ),
          Positioned(
            right: -8,
            top: compact ? 18 : 34,
            child: _SmallPhoto(
              asset: 'assets/images/ikan bakar kuala perlis.jpeg',
              label: 'Coastal grill',
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPhoto extends StatelessWidget {
  const _SmallPhoto({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AspectRatio(
              aspectRatio: 1.28,
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.cocoa,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePill extends StatelessWidget {
  const _ImagePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.cocoa,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.cocoa,
          fontWeight: FontWeight.w900,
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

class _MetricRow extends StatelessWidget {
  const _MetricRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricChip(
          icon: Icons.storefront_rounded,
          value: '50+',
          label: 'spots',
        ),
        _MetricChip(icon: Icons.place_rounded, value: 'Perlis', label: 'trail'),
        _MetricChip(
          icon: Icons.view_in_ar_rounded,
          value: 'AR',
          label: 'stories',
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.sand),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppTheme.clay),
          const SizedBox(width: 7),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.cocoa,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final cards = const [
          _DecisionCard(
            icon: Icons.visibility_rounded,
            title: 'See the dish first',
            description: 'Real food photography creates instant appetite.',
            color: Color(0xFFD45720),
          ),
          _DecisionCard(
            icon: Icons.tune_rounded,
            title: 'Choose with clarity',
            description:
                'Location, cuisine, halal status, and saves stay easy.',
            color: Color(0xFF226B5F),
          ),
          _DecisionCard(
            icon: Icons.favorite_rounded,
            title: 'Build your story',
            description: 'Favourites turn each visit into a personal trail.',
            color: Color(0xFF9D4F3F),
          ),
        ];

        if (!wide) {
          return Column(
            children: [
              for (final card in cards) ...[card, const SizedBox(height: 10)],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index != cards.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.sand),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SignalIcon(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.cocoa,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.mutedBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPreview extends StatelessWidget {
  const _JourneyPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F241F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A calmer way to explore Perlis food',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start with appetite, narrow the choice, then keep the places that become part of your travel memory.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          );
          final photos = const _PhotoStrip();

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 16), photos],
            );
          }

          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 18),
              const SizedBox(width: 320, child: _PhotoStrip()),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StripPhoto(asset: 'assets/images/nasi_kandar.jpg')),
        SizedBox(width: 8),
        Expanded(
          child: _StripPhoto(asset: 'assets/images/harum manis perlis.jpeg'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StripPhoto(asset: 'assets/images/pulut harum manis.jpg'),
        ),
      ],
    );
  }
}

class _StripPhoto extends StatelessWidget {
  const _StripPhoto({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 0.88,
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}

class _SignalIcon extends StatelessWidget {
  const _SignalIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
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
