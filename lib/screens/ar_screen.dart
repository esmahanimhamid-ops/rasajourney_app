import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/restaurant.dart';
import '../theme/app_theme.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key, this.initialFoodId});

  final String? initialFoodId;

  static const foods = [
    ARFoodDish(
      id: 'harum_manis',
      name: 'Harum Manis',
      imageAsset: 'assets/images/harum manis perlis.jpeg',
      shortDescription:
          'A fragrant Perlis mango known for its sweet taste and smooth flesh.',
      culturalStory:
          'Harum Manis is one of Perlis most iconic seasonal products. It is often associated with local farms, harvest season, and food tourism in the state.',
      ingredients: ['Fresh Harum Manis mango'],
      allergens: ['Usually none', 'Avoid if allergic to mango or latex-fruit'],
      keywords: ['harum manis', 'mango', 'mangga'],
      color: Color(0xFFF0A43B),
    ),
    ARFoodDish(
      id: 'laksa_perlis',
      name: 'Laksa Perlis',
      imageAsset: 'assets/images/laksa_perlis.jpg',
      shortDescription:
          'A northern-style laksa with rice noodles, fish gravy, herbs, and a tangy finish.',
      culturalStory:
          'Laksa Perlis reflects the northern Malaysian love for fish-based gravy, fresh herbs, and bright sour flavours. It is commonly enjoyed as a local comfort dish.',
      ingredients: ['Rice noodles', 'Fish gravy', 'Herbs', 'Cucumber', 'Onion'],
      allergens: ['Fish', 'Possible shrimp paste', 'Gluten if noodles vary'],
      keywords: ['laksa', 'laksa perlis', 'asam laksa'],
      color: Color(0xFFE9552F),
    ),
    ARFoodDish(
      id: 'nasi_ulam',
      name: 'Nasi Ulam',
      imageAsset: 'assets/images/nasi ulam.jpeg',
      shortDescription:
          'Rice mixed with fresh local herbs, vegetables, and savoury side flavours.',
      culturalStory:
          'Nasi Ulam celebrates kampung-style eating where herbs and greens are used for aroma, texture, and freshness. It fits Perlis food culture because it highlights simple local ingredients.',
      ingredients: [
        'Rice',
        'Ulam herbs',
        'Vegetables',
        'Grated coconut',
        'Sambal',
      ],
      allergens: ['Possible fish or shrimp in sambal', 'Coconut'],
      keywords: ['nasi ulam', 'ulam', 'herb rice'],
      color: Color(0xFF4F8F45),
    ),
    ARFoodDish(
      id: 'pulut_harum_manis',
      name: 'Pulut Harum Manis',
      imageAsset: 'assets/images/pulut harum manis.jpg',
      shortDescription:
          'Glutinous rice served with ripe Harum Manis mango and coconut milk.',
      culturalStory:
          'This dessert-style dish combines Perlis famous mango with pulut, making it a strong local showcase item for food tourism demos and seasonal promotions.',
      ingredients: [
        'Glutinous rice',
        'Harum Manis mango',
        'Coconut milk',
        'Sugar',
        'Salt',
      ],
      allergens: ['Coconut', 'Possible dairy if recipe is modified'],
      keywords: ['pulut harum manis', 'pulut', 'mango sticky rice'],
      color: Color(0xFFD69B2D),
    ),
    ARFoodDish(
      id: 'ikan_bakar',
      name: 'Ikan Bakar',
      imageAsset: 'assets/images/ikan bakar kuala perlis.jpeg',
      shortDescription:
          'Grilled fish seasoned with spices and usually served with dipping sauce.',
      culturalStory:
          'Ikan Bakar is strongly linked with Kuala Perlis and coastal dining. It represents seafood culture, family meals, and the fresh catch experience near the sea.',
      ingredients: ['Fish', 'Chilli paste', 'Turmeric', 'Lime', 'Sambal sauce'],
      allergens: ['Fish', 'Possible shrimp paste', 'Chilli sensitivity'],
      keywords: ['ikan bakar', 'grilled fish', 'seafood', 'bbq', 'grill'],
      color: Color(0xFF8D5B2F),
    ),
  ];

  static ARFoodDish foodById(String? id) {
    return foods.firstWhere((food) => food.id == id, orElse: () => foods.first);
  }

  static ARFoodDish relatedFoodForRestaurant(Restaurant restaurant) {
    final haystack = [
      restaurant.name,
      restaurant.restaurantType,
      ...restaurant.menuItems,
      ...restaurant.reviews.take(3),
    ].join(' ').toLowerCase();

    for (final food in foods) {
      if (food.keywords.any(haystack.contains)) {
        return food;
      }
    }

    if (restaurant.restaurantType == 'BBQ & Grill' ||
        restaurant.restaurantType == 'Seafood') {
      return foodById('ikan_bakar');
    }

    if (restaurant.restaurantType == 'Authentic Malay Cuisine' ||
        restaurant.restaurantType == 'Local Cuisine') {
      return foodById('laksa_perlis');
    }

    return foods.first;
  }

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  final _imagePicker = ImagePicker();
  final _assetSignatures = <String, _ImageSignature>{};

  late ARFoodDish _selectedFood;
  ARFoodDish? _showcaseFood;
  String? _scannedFoodImagePath;
  String? _scannerMessage;
  bool _isMatchingFood = false;

  @override
  void initState() {
    super.initState();
    _selectedFood = ARScreen.foodById(widget.initialFoodId);
    _showcaseFood = widget.initialFoodId == null ? null : _selectedFood;
  }

  void _openShowcase() {
    setState(() {
      _showcaseFood = _selectedFood;
    });
  }

  Future<void> _scanFood(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _scannedFoodImagePath = image.path;
      _showcaseFood = null;
      _isMatchingFood = true;
      _scannerMessage = 'Matching photo with local food inventory...';
    });

    try {
      final match = await _matchFoodFromImage(image.path);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedFood = match.food;
        _isMatchingFood = false;
        _scannerMessage =
            'Auto matched ${match.food.name} from local inventory. Tap View in AR to continue.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMatchingFood = false;
        _scannerMessage =
            'Photo scanned, but auto match was not available. You can still choose from the list.';
      });
    }
  }

  Future<_FoodImageMatch> _matchFoodFromImage(String imagePath) async {
    final scannedSignature = await _signatureFromFile(imagePath);
    final ruleMatch = _ruleBasedFoodMatch(scannedSignature);
    if (ruleMatch != null) {
      return ruleMatch;
    }

    _FoodImageMatch? bestMatch;
    for (final food in ARScreen.foods) {
      final assetSignature = await _signatureFromAsset(food.imageAsset);
      final distance = scannedSignature.distanceTo(assetSignature);
      final score = (1 - distance).clamp(0.0, 1.0);

      if (bestMatch == null || score > bestMatch.score) {
        bestMatch = _FoodImageMatch(food: food, score: score);
      }
    }

    return bestMatch!;
  }

  _FoodImageMatch? _ruleBasedFoodMatch(_ImageSignature signature) {
    final pulutCombo = math.min(signature.whiteRatio, signature.yellowRatio);

    final scores = <String, double>{
      'harum_manis':
          (signature.yellowRatio * 2.2) +
          (signature.greenRatio * 0.45) -
          (signature.whiteRatio * 1.35) -
          (pulutCombo * 2.0) -
          (signature.orangeRedRatio * 0.55) -
          (signature.darkRatio * 0.7) -
          (signature.cyanRatio * 0.45) -
          (signature.deepBlueRatio * 0.35),
      'laksa_perlis':
          (signature.whiteRatio * 0.85) +
          (signature.beigeRatio * 1.45) +
          (signature.deepBlueRatio * 1.7) +
          (signature.greenRatio * 0.55) +
          (signature.orangeRedRatio * 0.25) -
          (pulutCombo * 1.15) -
          (signature.charRatio * 1.1) -
          (signature.cyanRatio * 0.65) -
          (signature.yellowRatio * 0.55),
      'nasi_ulam':
          (signature.greenRatio * 2.8) +
          (signature.whiteRatio * 0.35) -
          (signature.orangeRedRatio * 0.4) -
          (signature.darkRatio * 0.35),
      'pulut_harum_manis':
          (signature.whiteRatio * 2.55) +
          (signature.yellowRatio * 1.85) +
          (pulutCombo * 4.0) -
          (signature.orangeRedRatio * 0.45) -
          (signature.darkRatio * 0.75) -
          (signature.deepBlueRatio * 1.2) -
          (signature.cyanRatio * 0.75) -
          (signature.greenRatio * 0.55) -
          (signature.beigeRatio * 0.45),
      'ikan_bakar':
          (signature.yellowRatio * 1.1) +
          (signature.orangeRedRatio * 1.05) +
          (signature.brownRatio * 1.35) +
          (signature.charRatio * 2.25) +
          (signature.cyanRatio * 1.25) -
          (signature.whiteRatio * 0.85) -
          (signature.deepBlueRatio * 0.6),
    };

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final winner = sorted.first;
    final runnerUp = sorted.length > 1 ? sorted[1].value : 0.0;

    if (winner.value < 0.18 || winner.value - runnerUp < 0.05) {
      return null;
    }

    return _FoodImageMatch(
      food: ARScreen.foodById(winner.key),
      score: winner.value.clamp(0.0, 1.0),
    );
  }

  Future<_ImageSignature> _signatureFromFile(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    return _signatureFromBytes(bytes);
  }

  Future<_ImageSignature> _signatureFromAsset(String assetPath) async {
    final cached = _assetSignatures[assetPath];
    if (cached != null) {
      return cached;
    }

    final data = await rootBundle.load(assetPath);
    final signature = await _signatureFromBytes(data.buffer.asUint8List());
    _assetSignatures[assetPath] = signature;
    return signature;
  }

  Future<_ImageSignature> _signatureFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 96,
      targetHeight: 96,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw StateError('Could not read image pixels.');
    }

    final width = image.width;
    final height = image.height;
    final pixels = byteData.buffer.asUint8List();
    final hueHistogram = List<double>.filled(12, 0);
    final regionSums = List<double>.filled(27, 0);
    final counts = List<int>.filled(9, 0);
    var usefulPixels = 0;
    var hueX = 0.0;
    var hueY = 0.0;
    var saturationSum = 0.0;
    var valueSum = 0.0;
    var yellowScore = 0.0;
    var greenScore = 0.0;
    var orangeRedScore = 0.0;
    var brownScore = 0.0;
    var whiteScore = 0.0;
    var darkScore = 0.0;
    var charScore = 0.0;
    var beigeScore = 0.0;
    var cyanScore = 0.0;
    var deepBlueScore = 0.0;
    var totalPixels = 0;

    for (var y = 0; y < height; y += 2) {
      for (var x = 0; x < width; x += 2) {
        final pixelIndex = (y * width + x) * 4;
        final red = pixels[pixelIndex] / 255;
        final green = pixels[pixelIndex + 1] / 255;
        final blue = pixels[pixelIndex + 2] / 255;
        final hsv = _rgbToHsv(red, green, blue);
        totalPixels++;

        final palePixel = hsv.saturation < 0.18 && hsv.value > 0.68;
        final darkPixel = hsv.value < 0.34;
        if (palePixel) {
          whiteScore++;
        }
        if (darkPixel) {
          darkScore++;
        }
        if (hsv.value < 0.42 && hsv.saturation > 0.22) {
          charScore += (1 - hsv.value) * hsv.saturation;
        }
        if (_isHueBetween(hsv.hue, 0.06, 0.15) &&
            hsv.saturation > 0.08 &&
            hsv.saturation < 0.38 &&
            hsv.value > 0.38 &&
            hsv.value < 0.9) {
          beigeScore += hsv.value * (1 - hsv.saturation);
        }
        if (_isHueBetween(hsv.hue, 0.10, 0.18) &&
            hsv.saturation > 0.24 &&
            hsv.value > 0.34) {
          yellowScore += hsv.saturation * hsv.value;
        }
        if (_isHueBetween(hsv.hue, 0.22, 0.45) &&
            hsv.saturation > 0.22 &&
            hsv.value > 0.24) {
          greenScore += hsv.saturation * hsv.value;
        }
        if (_isHueBetween(hsv.hue, 0.45, 0.56) &&
            hsv.saturation > 0.22 &&
            hsv.value > 0.22) {
          cyanScore += hsv.saturation * hsv.value;
        }
        if (_isHueBetween(hsv.hue, 0.56, 0.72) &&
            hsv.saturation > 0.22 &&
            hsv.value > 0.18) {
          deepBlueScore += hsv.saturation * hsv.value;
        }
        if ((_isHueBetween(hsv.hue, 0.0, 0.10) ||
                _isHueBetween(hsv.hue, 0.94, 1.0)) &&
            hsv.saturation > 0.26 &&
            hsv.value > 0.26) {
          orangeRedScore += hsv.saturation * hsv.value;
        }
        if (_isHueBetween(hsv.hue, 0.04, 0.13) &&
            hsv.saturation > 0.28 &&
            hsv.value > 0.18 &&
            hsv.value < 0.64) {
          brownScore += hsv.saturation * (1 - hsv.value);
        }

        // Skip flat background/plate pixels so the food color carries more weight.
        if (hsv.saturation < 0.16 || hsv.value < 0.16 || hsv.value > 0.96) {
          continue;
        }

        final regionX = math.min(2, x * 3 ~/ width);
        final regionY = math.min(2, y * 3 ~/ height);
        final region = regionY * 3 + regionX;
        final featureIndex = region * 3;
        final hueRadians = hsv.hue * math.pi * 2;
        final hueBucket = math.min(11, (hsv.hue * 12).floor());

        hueHistogram[hueBucket] += hsv.saturation * hsv.value;
        hueX += math.cos(hueRadians) * hsv.saturation;
        hueY += math.sin(hueRadians) * hsv.saturation;
        saturationSum += hsv.saturation;
        valueSum += hsv.value;
        regionSums[featureIndex] += red;
        regionSums[featureIndex + 1] += green;
        regionSums[featureIndex + 2] += blue;
        counts[region]++;
        usefulPixels++;
      }
    }

    image.dispose();

    if (usefulPixels == 0) {
      throw StateError('Could not find enough food pixels in image.');
    }

    final histogramTotal = hueHistogram.fold<double>(0, (sum, value) {
      return sum + value;
    });
    if (histogramTotal > 0) {
      for (var index = 0; index < hueHistogram.length; index++) {
        hueHistogram[index] /= histogramTotal;
      }
    }

    for (var region = 0; region < counts.length; region++) {
      final count = counts[region];
      if (count == 0) {
        continue;
      }

      final featureIndex = region * 3;
      regionSums[featureIndex] /= count;
      regionSums[featureIndex + 1] /= count;
      regionSums[featureIndex + 2] /= count;
    }

    final averageHue = math.atan2(hueY, hueX) / (math.pi * 2);
    return _ImageSignature(
      hueHistogram: hueHistogram,
      averageHue: averageHue < 0 ? averageHue + 1 : averageHue,
      averageSaturation: saturationSum / usefulPixels,
      averageValue: valueSum / usefulPixels,
      regionFeatures: regionSums,
      yellowRatio: yellowScore / totalPixels,
      greenRatio: greenScore / totalPixels,
      orangeRedRatio: orangeRedScore / totalPixels,
      brownRatio: brownScore / totalPixels,
      whiteRatio: whiteScore / totalPixels,
      darkRatio: darkScore / totalPixels,
      charRatio: charScore / totalPixels,
      beigeRatio: beigeScore / totalPixels,
      cyanRatio: cyanScore / totalPixels,
      deepBlueRatio: deepBlueScore / totalPixels,
    );
  }

  bool _isHueBetween(double hue, double start, double end) {
    return hue >= start && hue <= end;
  }

  _HsvColor _rgbToHsv(double red, double green, double blue) {
    final maxValue = math.max(red, math.max(green, blue));
    final minValue = math.min(red, math.min(green, blue));
    final delta = maxValue - minValue;

    var hue = 0.0;
    if (delta != 0) {
      if (maxValue == red) {
        hue = ((green - blue) / delta) % 6;
      } else if (maxValue == green) {
        hue = ((blue - red) / delta) + 2;
      } else {
        hue = ((red - green) / delta) + 4;
      }
      hue /= 6;
      if (hue < 0) {
        hue += 1;
      }
    }

    return _HsvColor(
      hue: hue,
      saturation: maxValue == 0 ? 0 : delta / maxValue,
      value: maxValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showcaseFood = _showcaseFood;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          showcaseFood == null ? 'AR Food Showcase' : showcaseFood.name,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.cream, AppTheme.warmWhite],
          ),
        ),
        child: SafeArea(
          child: showcaseFood == null
              ? _FoodSelectionView(
                  selectedFood: _selectedFood,
                  foods: ARScreen.foods,
                  scannedFoodImagePath: _scannedFoodImagePath,
                  scannerMessage: _scannerMessage,
                  isMatchingFood: _isMatchingFood,
                  onSelected: (food) => setState(() => _selectedFood = food),
                  onScanFood: () => _scanFood(ImageSource.camera),
                  onChoosePhoto: () => _scanFood(ImageSource.gallery),
                  onViewInAR: _openShowcase,
                )
              : _ARFoodShowcaseView(
                  food: showcaseFood,
                  onChooseAnother: () => setState(() => _showcaseFood = null),
                ),
        ),
      ),
    );
  }
}

class ARFoodDish {
  const ARFoodDish({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.shortDescription,
    required this.culturalStory,
    required this.ingredients,
    required this.allergens,
    required this.keywords,
    required this.color,
  });

  final String id;
  final String name;
  final String imageAsset;
  final String shortDescription;
  final String culturalStory;
  final List<String> ingredients;
  final List<String> allergens;
  final List<String> keywords;
  final Color color;
}

class _FoodImageMatch {
  const _FoodImageMatch({required this.food, required this.score});

  final ARFoodDish food;
  final double score;
}

class _HsvColor {
  const _HsvColor({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;
}

class _ImageSignature {
  const _ImageSignature({
    required this.hueHistogram,
    required this.averageHue,
    required this.averageSaturation,
    required this.averageValue,
    required this.regionFeatures,
    required this.yellowRatio,
    required this.greenRatio,
    required this.orangeRedRatio,
    required this.brownRatio,
    required this.whiteRatio,
    required this.darkRatio,
    required this.charRatio,
    required this.beigeRatio,
    required this.cyanRatio,
    required this.deepBlueRatio,
  });

  final List<double> hueHistogram;
  final double averageHue;
  final double averageSaturation;
  final double averageValue;
  final List<double> regionFeatures;
  final double yellowRatio;
  final double greenRatio;
  final double orangeRedRatio;
  final double brownRatio;
  final double whiteRatio;
  final double darkRatio;
  final double charRatio;
  final double beigeRatio;
  final double cyanRatio;
  final double deepBlueRatio;

  double distanceTo(_ImageSignature other) {
    var histogramDistance = 0.0;
    for (var index = 0; index < hueHistogram.length; index++) {
      histogramDistance += (hueHistogram[index] - other.hueHistogram[index])
          .abs();
    }
    histogramDistance /= 2;

    final hueDelta = (averageHue - other.averageHue).abs();
    final circularHueDistance = math.min(hueDelta, 1 - hueDelta);
    final saturationDistance = (averageSaturation - other.averageSaturation)
        .abs();
    final valueDistance = (averageValue - other.averageValue).abs();

    var regionSum = 0.0;
    for (var index = 0; index < regionFeatures.length; index++) {
      final delta = regionFeatures[index] - other.regionFeatures[index];
      regionSum += delta * delta;
    }
    final regionDistance = math.sqrt(regionSum / regionFeatures.length);

    return (histogramDistance * 0.55) +
        (circularHueDistance * 0.2) +
        (saturationDistance * 0.1) +
        (valueDistance * 0.05) +
        (regionDistance * 0.1);
  }
}

class _FoodSelectionView extends StatelessWidget {
  const _FoodSelectionView({
    required this.selectedFood,
    required this.foods,
    required this.scannedFoodImagePath,
    required this.scannerMessage,
    required this.isMatchingFood,
    required this.onSelected,
    required this.onScanFood,
    required this.onChoosePhoto,
    required this.onViewInAR,
  });

  final ARFoodDish selectedFood;
  final List<ARFoodDish> foods;
  final String? scannedFoodImagePath;
  final String? scannerMessage;
  final bool isMatchingFood;
  final ValueChanged<ARFoodDish> onSelected;
  final VoidCallback onScanFood;
  final VoidCallback onChoosePhoto;
  final VoidCallback onViewInAR;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Choose Local Food',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.cocoa,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan a food photo or select a Perlis food manually, then open the AR showcase.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        _ScannerCard(
          scannedFoodImagePath: scannedFoodImagePath,
          scannerMessage: scannerMessage,
          isMatchingFood: isMatchingFood,
          onScanFood: onScanFood,
          onChoosePhoto: onChoosePhoto,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<ARFoodDish>(
          initialValue: selectedFood,
          decoration: const InputDecoration(labelText: 'Food'),
          items: foods
              .map(
                (food) => DropdownMenuItem(value: food, child: Text(food.name)),
              )
              .toList(),
          onChanged: (food) {
            if (food != null) {
              onSelected(food);
            }
          },
        ),
        const SizedBox(height: 18),
        _FoodPreviewCard(food: selectedFood),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isMatchingFood ? null : onViewInAR,
            icon: const Icon(Icons.view_in_ar_outlined),
            label: const Text('View in AR'),
          ),
        ),
        const SizedBox(height: 18),
        ...foods.map(
          (food) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FoodListTile(
              food: food,
              selected: food.id == selectedFood.id,
              onTap: () => onSelected(food),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerCard extends StatelessWidget {
  const _ScannerCard({
    required this.scannedFoodImagePath,
    required this.scannerMessage,
    required this.isMatchingFood,
    required this.onScanFood,
    required this.onChoosePhoto,
  });

  final String? scannedFoodImagePath;
  final String? scannerMessage;
  final bool isMatchingFood;
  final VoidCallback onScanFood;
  final VoidCallback onChoosePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.clay.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.45,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: scannedFoodImagePath == null
                  ? Container(
                      color: AppTheme.blush,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.document_scanner_outlined, size: 46),
                            SizedBox(height: 10),
                            Text(
                              'Scan food image',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Image.file(File(scannedFoodImagePath!), fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scannerMessage ??
                      (scannedFoodImagePath == null
                          ? 'Use the camera scanner or choose an existing photo.'
                          : 'Photo scanned. The closest local food is selected below.'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isMatchingFood ? null : onScanFood,
                        icon: isMatchingFood
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt_outlined),
                        label: Text(isMatchingFood ? 'Matching...' : 'Scan'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: isMatchingFood ? null : onChoosePhoto,
                      tooltip: 'Choose photo',
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ARFoodShowcaseView extends StatelessWidget {
  const _ARFoodShowcaseView({
    required this.food,
    required this.onChooseAnother,
  });

  final ARFoodDish food;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ARPlaceholder(food: food),
        const SizedBox(height: 18),
        _FoodPreviewCard(food: food),
        const SizedBox(height: 18),
        _InfoSection(
          icon: Icons.history_edu_outlined,
          title: 'Cultural Story',
          child: Text(
            food.culturalStory,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
        const SizedBox(height: 14),
        _InfoSection(
          icon: Icons.restaurant_menu_rounded,
          title: 'Ingredients',
          child: _ChipWrap(values: food.ingredients),
        ),
        const SizedBox(height: 14),
        _InfoSection(
          icon: Icons.warning_amber_rounded,
          title: 'Allergen Reminder',
          child: _ChipWrap(values: food.allergens, warning: true),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: onChooseAnother,
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Choose Another Food'),
        ),
      ],
    );
  }
}

class _ARPlaceholder extends StatelessWidget {
  const _ARPlaceholder({required this.food});

  final ARFoodDish food;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          color: food.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: food.color.withValues(alpha: 0.22)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(food.imageAsset, fit: BoxFit.cover),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.view_in_ar_outlined,
                      color: Colors.white,
                      size: 58,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      food.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AR model coming soon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodPreviewCard extends StatelessWidget {
  const _FoodPreviewCard({required this.food});

  final ARFoodDish food;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: food.color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.55,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Image.asset(food.imageAsset, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.cocoa,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  food.shortDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedBrown,
                    height: 1.45,
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

class _FoodListTile extends StatelessWidget {
  const _FoodListTile({
    required this.food,
    required this.selected,
    required this.onTap,
  });

  final ARFoodDish food;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? food.color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? food.color.withValues(alpha: 0.45)
                : AppTheme.sand,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                food.imageAsset,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                food.name,
                style: const TextStyle(
                  color: AppTheme.cocoa,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? food.color : AppTheme.mutedBrown,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.clay),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.cocoa,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.values, this.warning = false});

  final List<String> values;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final foreground = warning ? Colors.red.shade800 : AppTheme.cocoa;
    final background = warning
        ? Colors.red.withValues(alpha: 0.08)
        : AppTheme.amber.withValues(alpha: 0.16);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
