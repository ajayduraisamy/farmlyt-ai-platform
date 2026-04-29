// ==================== USER MODEL ====================
int _modelParseInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '0') ?? 0;

DateTime? _modelParseDate(String value) {
  if (value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value) ??
      DateTime.tryParse(value.replaceFirst(' GMT', ''));
}

String? _sanitizeApiImageUrl(String? rawUrl) {
  final normalized = rawUrl?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return Uri.encodeFull(normalized);
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String token;
  final int credits;
  final String? profileImagePath;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.token,
    this.credits = 50,
    this.profileImagePath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ??
            json['full_name']?.toString() ??
            json['fullName']?.toString() ??
            json['username']?.toString() ??
            json['user_name']?.toString() ??
            json['display_name']?.toString() ??
            json['displayName']?.toString() ??
            '',
        phone: json['phone']?.toString() ??
            json['mobile']?.toString() ??
            json['phone_number']?.toString() ??
            json['phoneNumber']?.toString() ??
            '',
        email: json['email']?.toString() ?? '',
        token:
            json['token']?.toString() ?? json['access_token']?.toString() ?? '',
        credits: json['credits'] is int
            ? json['credits'] as int
            : int.tryParse(json['credits']?.toString() ?? '50') ?? 50,
        profileImagePath: json['profile_image_path']?.toString() ??
            json['profileImagePath']?.toString(),
      );

  UserModel copyWith(
          {String? id,
          String? name,
          String? phone,
          String? email,
          String? token,
          int? credits,
          String? profileImagePath}) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        token: token ?? this.token,
        credits: credits ?? this.credits,
        profileImagePath: profileImagePath ?? this.profileImagePath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'token': token,
        'credits': credits,
        'profile_image_path': profileImagePath,
      };
}

// ==================== WEATHER MODEL ====================

class WeatherModel {
  final double temperature;
  final int weatherCode;
  final double windspeed;
  final int isDay;
  final String time;
  final double apparentTemperature;

  // ── NEW: Health Indicators ──
  final double uvIndex;
  final double soilTemperature;
  final double soilMoisture;

  // Forecast Fields
  final List<String> dailyTime;
  final List<double> dailyMaxTemp;
  final List<int> dailyWeatherCode;

  // Hourly Fields for Premium Graph
  final List<String> hourlyTime;
  final List<double> hourlyTemperature;
  final List<int> hourlyHumidity;
  final List<int> hourlyRainChance;

  WeatherModel({
    required this.temperature,
    required this.weatherCode,
    required this.windspeed,
    required this.isDay,
    required this.time,
    this.apparentTemperature = 0.0,
    required this.uvIndex,
    required this.soilTemperature,
    required this.soilMoisture,
    required this.dailyTime,
    required this.dailyMaxTemp,
    required this.dailyWeatherCode,
    required this.hourlyTime,
    required this.hourlyTemperature,
    required this.hourlyHumidity,
    required this.hourlyRainChance,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final c = json['current_weather'] as Map? ?? {};
    final d = json['daily'] as Map? ?? {};
    final h = json['hourly'] as Map? ?? {};

    // apparent_temperature comes from hourly list — take first value
    final hourlyApparent = h['apparent_temperature'] as List?;
    final apparentTemp = hourlyApparent != null && hourlyApparent.isNotEmpty
        ? (hourlyApparent[0] as num).toDouble()
        : (c['temperature'] as num? ?? 0).toDouble();

    // ── NEW: Parsing UV and Soil from hourly data (taking the 1st hour value/current) ──
    final hourlyUv = h['uv_index'] as List?;
    final uvValue = hourlyUv != null && hourlyUv.isNotEmpty
        ? (hourlyUv[0] as num).toDouble()
        : 0.0;

    final hourlySoilTemp = h['soil_temperature_0cm'] as List?;
    final soilTempVal = hourlySoilTemp != null && hourlySoilTemp.isNotEmpty
        ? (hourlySoilTemp[0] as num).toDouble()
        : 0.0;

    final hourlySoilMoist = h['soil_moisture_0_to_1cm'] as List?;
    final soilMoistVal = hourlySoilMoist != null && hourlySoilMoist.isNotEmpty
        ? (hourlySoilMoist[0] as num).toDouble()
        : 0.0;

    return WeatherModel(
      temperature: (c['temperature'] as num? ?? 0).toDouble(),
      weatherCode: int.tryParse(c['weathercode']?.toString() ?? '0') ?? 0,
      windspeed: (c['windspeed'] as num? ?? 0).toDouble(),
      isDay: c['is_day'] as int? ?? 1,
      time: c['time']?.toString() ?? '',
      apparentTemperature: apparentTemp,

      // ── Mapped Health Indicators ──
      uvIndex: uvValue,
      soilTemperature: soilTempVal,
      soilMoisture: soilMoistVal,

      // Daily lists
      dailyTime: List<String>.from(d['time'] as List? ?? []),
      dailyMaxTemp: ((d['temperature_2m_max'] as List?) ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      dailyWeatherCode: ((d['weathercode'] as List?) ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList(),

      // Hourly data parsing
      hourlyTime: List<String>.from(h['time'] as List? ?? []),
      hourlyTemperature: ((h['temperature_2m'] as List?) ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      hourlyHumidity: ((h['relative_humidity_2m'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      hourlyRainChance: ((h['precipitation_probability'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }

  String get weatherEmoji => _getEmoji(weatherCode, isDay == 1);

  static String _getEmoji(int code, bool day) {
    if (code == 0) return day ? '☀️' : '🌙';
    if (code <= 3) return '⛅';
    if (code <= 49) return '🌫️';
    if (code <= 69) return '🌧️';
    if (code <= 82) return '🌦️';
    return '⛈️';
  }
}

// ==================== AGRI TITLE MODEL ====================
class AgriTitle {
  final int id;
  final String title;
  final String? imageUrl;
  final DateTime? createdAt;

  const AgriTitle({
    required this.id,
    required this.title,
    this.imageUrl,
    this.createdAt,
  });

  factory AgriTitle.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['title']?.toString() ?? '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final rawCreatedAt = json['created_at']?.toString() ?? '';

    return AgriTitle(
      id: _modelParseInt(json['id']),
      title: rawTitle,
      imageUrl: _sanitizeApiImageUrl(json['image_url']?.toString()),
      createdAt: _modelParseDate(rawCreatedAt),
    );
  }

  String get normalizedTitle =>
      title.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  bool get isAgricultureDiseaseScan =>
      id == 1 ||
      (normalizedTitle.contains('agriculture') &&
          normalizedTitle.contains('disease') &&
          normalizedTitle.contains('scan'));

  String get icon {
    if (normalizedTitle.contains('disease')) return '🔎';
    if (normalizedTitle.contains('identification')) return '🪴';
    if (normalizedTitle.contains('food')) return '🌾';
    if (normalizedTitle.contains('vegetable')) return '🥬';
    return '🌿';
  }

  int get color {
    const palette = <int>[
      0xFF2E7D32,
      0xFFFF8F00,
      0xFF1565C0,
      0xFFAD1457,
      0xFF00695C,
      0xFF4E342E,
    ];
    final index = id <= 0 ? 0 : (id - 1) % palette.length;
    return palette[index];
  }

  String get subtitle => '';
}

// ==================== CROP OPTION MODEL ====================
class CropOption {
  final int id;
  final int categoryId;
  final String categoryTitle;
  final String title;
  final String cropKey;
  final String? imageUrl;
  final DateTime? createdDate;

  const CropOption({
    required this.id,
    required this.categoryId,
    required this.categoryTitle,
    required this.title,
    required this.cropKey,
    this.imageUrl,
    this.createdDate,
  });

  factory CropOption.fromJson(Map<String, dynamic> json) {
    final rawTitle = _normalizeTitle(json['title']?.toString() ?? '');
    final rawCategoryTitle =
        _normalizeTitle(json['crop_name']?.toString() ?? '');
    final createdRaw = json['created_date']?.toString() ?? '';

    return CropOption(
      id: _parseInt(json['id']),
      categoryId: _parseInt(json['crop_id']),
      categoryTitle: rawCategoryTitle,
      title: rawTitle,
      cropKey: cropKeyFromTitle(rawTitle),
      imageUrl: _normalizeImageUrl(json['image_url']?.toString()),
      createdDate: _parseDate(createdRaw),
    );
  }

  CropOption copyWith({
    int? id,
    int? categoryId,
    String? categoryTitle,
    String? title,
    String? cropKey,
    String? imageUrl,
    DateTime? createdDate,
  }) =>
      CropOption(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        categoryTitle: categoryTitle ?? this.categoryTitle,
        title: title ?? this.title,
        cropKey: cropKey ?? this.cropKey,
        imageUrl: imageUrl ?? this.imageUrl,
        createdDate: createdDate ?? this.createdDate,
      );

  static int _parseInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '0') ?? 0;

  static DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value) ??
        DateTime.tryParse(value.replaceFirst(' GMT', ''));
  }

  static String? _normalizeImageUrl(String? imageUrl) {
    return _sanitizeApiImageUrl(imageUrl);
  }

  static String _normalizeTitle(String rawValue) =>
      rawValue.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String cropKeyFromTitle(String rawTitle) {
    return DetectionCategory.normalizeCropKey(rawTitle);
  }
}

// ==================== DETECTION CATEGORY MODEL ====================
/// Built dynamically from GET /get_crops + GET /get_crop_sub API responses
class DetectionCategory {
  final int backendId;
  final int agriId;
  final String agriTitle;
  final String id; // internal id: 'leaf', 'fruit', 'flower', 'vegetable'
  final String apiPath; // path prefix: 'leafs', 'fruits', etc.
  final String title;
  final String icon;
  final int color;
  final List<String> crops; // crop keys from API e.g. ['tomato','potato']
  final List<CropOption> cropOptions;
  final String? imageUrl;

  DetectionCategory({
    required this.backendId,
    this.agriId = 0,
    this.agriTitle = '',
    required this.id,
    required this.apiPath,
    required this.title,
    required this.icon,
    required this.color,
    this.crops = const <String>[],
    this.cropOptions = const <CropOption>[],
    this.imageUrl,
  });

  DetectionCategory copyWith({
    int? backendId,
    int? agriId,
    String? agriTitle,
    String? id,
    String? apiPath,
    String? title,
    String? icon,
    int? color,
    List<String>? crops,
    List<CropOption>? cropOptions,
    String? imageUrl,
  }) =>
      DetectionCategory(
        backendId: backendId ?? this.backendId,
        agriId: agriId ?? this.agriId,
        agriTitle: agriTitle ?? this.agriTitle,
        id: id ?? this.id,
        apiPath: apiPath ?? this.apiPath,
        title: title ?? this.title,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        crops: crops ?? this.crops,
        cropOptions: cropOptions ?? this.cropOptions,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  DetectionCategory withCropOptions(List<CropOption> options) {
    final sortedOptions = [...options]..sort((a, b) => a.id.compareTo(b.id));
    return copyWith(
      cropOptions: sortedOptions,
      crops: sortedOptions.map((option) => option.cropKey).toList(),
    );
  }

  List<String> get availableCrops {
    if (cropOptions.isNotEmpty) {
      return cropOptions.map((option) => option.cropKey).toList();
    }
    return _normalizeCropKeys(crops);
  }

  bool get hasCropOptions =>
      cropOptions.isNotEmpty || availableCrops.isNotEmpty;

  Set<String> get discoveryTokens {
    final tokens = <String>{};

    void addToken(String rawValue) {
      final normalized = normalizeCropKey(rawValue);
      if (normalized.isEmpty) return;
      tokens.add(normalized);
      if (normalized.endsWith('s') && normalized.length > 1) {
        tokens.add(normalized.substring(0, normalized.length - 1));
      }
    }

    addToken(id);
    addToken(apiPath);
    addToken(_idFromTitle(title));
    for (final part in title.split(RegExp(r'[^A-Za-z]+'))) {
      final lowered = part.trim().toLowerCase();
      if (lowered.isEmpty ||
          lowered == 'detection' ||
          lowered == 'analysis' ||
          lowered == 'analyze' ||
          lowered == 'detector') {
        continue;
      }
      addToken(lowered);
    }

    return tokens;
  }

  String? discoverCropKey(String rawCropKey) {
    final normalizedCropKey = normalizeCropKey(rawCropKey);
    if (normalizedCropKey.isEmpty) return null;

    final knownCrops = availableCrops.toSet();
    if (knownCrops.contains(normalizedCropKey)) {
      return normalizedCropKey;
    }

    for (final token in discoveryTokens) {
      if (normalizedCropKey == token) {
        return normalizedCropKey;
      }

      if (normalizedCropKey.startsWith('${token}_')) {
        final stripped = normalizedCropKey.substring(token.length + 1);
        if (stripped.isNotEmpty) {
          return stripped;
        }
      }

      if (normalizedCropKey.endsWith('_$token')) {
        final stripped = normalizedCropKey.substring(
          0,
          normalizedCropKey.length - token.length - 1,
        );
        if (stripped.isNotEmpty) {
          return stripped;
        }
      }
    }

    return null;
  }

  String get subtitle {
    final displayCrops = cropOptions.isNotEmpty
        ? cropOptions
            .map((option) => option.title.trim())
            .where((title) => title.isNotEmpty)
            .toList()
        : availableCrops
            .map((crop) => _capitalize(crop.replaceAll('_', ' ')))
            .toList();
    if (displayCrops.isEmpty) return '';
    return displayCrops.take(3).join(', ') +
        (displayCrops.length > 3 ? '...' : '');
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  factory DetectionCategory.fromApiJson(
    Map<String, dynamic> json, {
    List<CropOption> cropOptions = const <CropOption>[],
  }) {
    final rawTitle = (json['title']?.toString() ?? '').trim();
    final backendId = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final rawApiPath = (json['api_path'] as String? ??
            json['apiPath'] as String? ??
            json['path'] as String? ??
            json['slug'] as String? ??
            json['category'] as String?)
        ?.trim();
    final id = rawApiPath?.isNotEmpty == true
        ? _normalizeId(rawApiPath!)
        : _idFromTitle(rawTitle);

    return DetectionCategory(
      backendId: backendId,
      agriId: json['agri_id'] is int
          ? json['agri_id'] as int
          : int.tryParse(json['agri_id']?.toString() ?? '0') ?? 0,
      agriTitle: (json['agri_title']?.toString() ?? '').trim(),
      id: id,
      apiPath: _apiPathForId(id, rawApiPath: rawApiPath, rawTitle: rawTitle),
      title: rawTitle.isNotEmpty ? rawTitle : _titleForId(id),
      icon: _iconForId(id),
      color: _colorForId(id),
      cropOptions: cropOptions,
      crops: cropOptions.map((option) => option.cropKey).toList(),
      imageUrl: _normalizeImageUrl(
        json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      ),
    );
  }

  static String _normalizeId(String key) {
    switch (key.toLowerCase()) {
      case 'leafs':
      case 'leaves':
        return 'leaf';
      case 'fruits':
        return 'fruit';
      case 'flowers':
        return 'flower';
      case 'vegtables':
      case 'vegitable':
      case 'vegitables':
      case 'vegetables':
        return 'vegetable';
      default:
        return normalizeCropKey(key);
    }
  }

  static String _idFromTitle(String title) {
    final normalized = title
        .trim()
        .toLowerCase()
        .replaceAll('analyse', 'analyze')
        .replaceAll('analysis', '')
        .replaceAll('analyze', '')
        .replaceAll('detection', '')
        .replaceAll('detector', '')
        .trim();
    if (normalized.contains('leaf')) return 'leaf';
    if (normalized.contains('fruit')) return 'fruit';
    if (normalized.contains('flower')) return 'flower';
    if (normalized.contains('veg')) return 'vegetable';
    if (normalized.contains('soil')) return 'soil';
    if (normalized.contains('plant')) return 'plant';
    return _normalizeId(normalized.replaceAll(' ', '_'));
  }

  static String _apiPathForId(
    String id, {
    String? rawApiPath,
    String? rawTitle,
  }) {
    if (rawApiPath != null && rawApiPath.trim().isNotEmpty) {
      return rawApiPath.trim();
    }

    switch (id) {
      case 'leaf':
        return 'leafs';
      case 'fruit':
        return 'fruits';
      case 'flower':
        return 'flowers';
      case 'vegetable':
        return 'vegtables';
      case 'soil':
        return 'soil';
      default:
        final normalizedTitle = normalizeCropKey(rawTitle ?? id)
            .replaceAll('_detection', '')
            .replaceAll('_analysis', '')
            .replaceAll('_analyze', '')
            .replaceAll('_detector', '');
        return normalizedTitle.isEmpty ? id : normalizedTitle;
    }
  }

  static List<String> _normalizeCropKeys(List<dynamic> rawCrops) => rawCrops
      .map((crop) => CropOption.cropKeyFromTitle(crop.toString()))
      .where((crop) => crop.isNotEmpty)
      .toList();

  static String normalizeCropKey(String rawValue) {
    final normalized = rawValue
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');

    const aliases = <String, String>{
      'chilli': 'chili',
      'lady_finger': 'ladyfinger',
      'lady_finger_leaf': 'ladyfinger',
      'tomato_fruit': 'tomato',
      'brinjal_veg': 'brinjal',
      'brinjal_vegetable': 'brinjal',
      'custard_apple': 'custard_apple',
      'ridge_gourd': 'ridge',
      'bitter_gourd': 'bitter_gourd',
      'rose_flower': 'rose',
      'jasmine_flower': 'jasmine',
      'chrysanthemum_flower': 'chrysanthemums',
      'chrysanthemum': 'chrysanthemum',
      'chrysanthemums': 'chrysanthemums',
    };

    return aliases[normalized] ?? normalized;
  }

  static String? _normalizeImageUrl(String? imageUrl) {
    return _sanitizeApiImageUrl(imageUrl);
  }

  static String _titleForId(String id) {
    switch (id) {
      case 'leaf':
        return 'Leaf Detection';
      case 'fruit':
        return 'Fruit Detection';
      case 'flower':
        return 'Flower Detection';
      case 'vegetable':
        return 'Vegetable Detection';
      case 'soil':
        return 'Soil Detection';
      default:
        final titleized = id
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
        return titleized.isEmpty ? 'Detection' : '$titleized Detection';
    }
  }

  static String _iconForId(String id) {
    switch (id) {
      case 'leaf':
        return '🍃';
      case 'fruit':
        return '🍋';
      case 'flower':
        return '🌸';
      case 'vegetable':
        return '🥦';
      case 'soil':
        return '🟫';
      case 'plant':
        return '🌱';
      default:
        return '🌿';
    }
  }

  static int _colorForId(String id) {
    switch (id) {
      case 'leaf':
        return 0xFF2E7D32;
      case 'fruit':
        return 0xFFFF8F00;
      case 'flower':
        return 0xFFAD1457;
      case 'vegetable':
        return 0xFF00695C;
      case 'soil':
        return 0xFF4E342E;
      default:
        const palette = <int>[
          0xFF2E7D32,
          0xFF1565C0,
          0xFF6A1B9A,
          0xFFEF6C00,
          0xFF00897B,
          0xFF5D4037,
        ];
        final hash = id.runes.fold<int>(0, (sum, unit) => sum + unit);
        return palette[hash % palette.length];
    }
  }

  Map<String, dynamic> toMap() => {
        'backendId': backendId,
        'agriId': agriId,
        'agriTitle': agriTitle,
        'id': id,
        'apiPath': apiPath,
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'color': color,
        'imageUrl': imageUrl,
        'crops': cropOptions
            .map((option) => {
                  'id': option.id,
                  'label': option.title,
                  'key': option.cropKey,
                  'imageUrl': option.imageUrl,
                })
            .toList(),
      };
}

class ProductRecommendation {
  final String productName;
  final String productImage;
  final String productUrl;

  ProductRecommendation({
    required this.productName,
    required this.productImage,
    required this.productUrl,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      productName: json['product_name']?.toString() ?? '',
      productImage: json['product_image']?.toString() ?? '',
      productUrl: json['product_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'product_name': productName,
        'product_image': productImage,
        'product_url': productUrl,
      };
}

class PredictionHistoryItem {
  final int id;
  final String crop;
  final String? disease;
  final String prediction;
  final String? imageUrl;
  final String? originalImageUrl;
  final String? predictedImageUrl;
  final List<String> fertilizers;
  final List<String> pesticides;
  final List<String> carePoints;
  final List<ProductRecommendation> products;
  final DateTime? createdAt;

  PredictionHistoryItem({
    required this.id,
    required this.crop,
    required this.prediction,
    this.disease,
    this.imageUrl,
    this.originalImageUrl,
    this.predictedImageUrl,
    this.fertilizers = const <String>[],
    this.pesticides = const <String>[],
    this.carePoints = const <String>[],
    this.products = const <ProductRecommendation>[],
    this.createdAt,
  });

  factory PredictionHistoryItem.fromJson(Map<String, dynamic> json) {
    final predictedImage = json['predicted_image']?.toString() ??
        json['predictedImage']?.toString();
    final originalImage =
        json['original_image']?.toString() ?? json['originalImage']?.toString();
    return PredictionHistoryItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      crop: json['crop']?.toString() ?? '',
      disease: json['disease']?.toString(),
      prediction: json['prediction']?.toString() ?? '',
      imageUrl: predictedImage ?? json['image_url']?.toString(),
      originalImageUrl: originalImage,
      predictedImageUrl: predictedImage,
      fertilizers: List<String>.from(json['fertilizers'] ?? const <String>[]),
      pesticides: List<String>.from(json['pesticides'] ?? const <String>[]),
      carePoints: List<String>.from(json['care_points'] ?? const <String>[]),
      products: (json['products'] as List?)
              ?.map((p) =>
                  ProductRecommendation.fromJson(Map<String, dynamic>.from(p)))
              .toList() ??
          const <ProductRecommendation>[],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

// ==================== DETECTION RESULT MODEL ====================
class DetectionResult {
  final String diseaseName;
  final double confidence;
  final String severity;
  final List<String> fertilizers;
  final List<String> pesticides;
  final List<String> actionSteps;
  final String description;
  final String? imageUrl;
  final String? originalImageUrl;
  final String? predictedImageUrl;
  final String predictionText;
  final List<ProductRecommendation> products;

  DetectionResult({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.fertilizers,
    required this.pesticides,
    required this.actionSteps,
    required this.description,
    this.imageUrl,
    this.originalImageUrl,
    this.predictedImageUrl,
    this.predictionText = '',
    this.products = const <ProductRecommendation>[],
  });

  /// Real API response format (Image 4 / Postman screenshot):
  /// {
  ///   "care_points": [...],
  ///   "disease": "unhealthy",
  ///   "fertilizers": ["Balanced NPK", "Micronutrient mix"],
  ///   "image_url": "https://...",
  ///   "message": "Prediction completed",
  ///   "pesticides": ["Neem oil", "General fungicide spray"],
  ///   "prediction": "unhealthy (0.93)\n"
  /// }
  factory DetectionResult.fromApiResponse(Map<String, dynamic> json) {
    final predictedImageUrl = json['predicted_image']?.toString() ??
        json['predictedImage']?.toString();
    final originalImageUrl =
        json['original_image']?.toString() ?? json['originalImage']?.toString();
    final imageUrl = predictedImageUrl ?? json['image_url']?.toString();

    final predictionRaw = (json['prediction'] as String? ?? '').trim();
    final diseaseRaw = (json['disease']?.toString() ?? '').trim();

    final parsedTop = _parseTopPrediction(predictionRaw);
    final topPredictionText = _topPredictionText(predictionRaw, parsedTop);
    final noDetection = predictionRaw.toLowerCase() == 'no detection';
    final diseaseIsGeneric = _isGenericDiseaseLabel(diseaseRaw);

    String diseaseName = diseaseRaw;
    if (parsedTop != null &&
        (diseaseName.isEmpty || diseaseIsGeneric || noDetection)) {
      diseaseName = parsedTop.key;
    }
    if (diseaseName.isEmpty && predictionRaw.isNotEmpty && !noDetection) {
      diseaseName = predictionRaw
          .split('\n')
          .map((line) => line.trim())
          .firstWhere((line) => line.isNotEmpty, orElse: () => '')
          .replaceAll('_', ' ');
    }
    if (diseaseName.isEmpty || noDetection) {
      diseaseName = 'No Disease Detected';
    }
    diseaseName = diseaseName.replaceAll('_', ' ').trim();

    double confidence = parsedTop?.value ??
        _normalizeConfidence(json['confidence'] ?? json['probability'] ?? 0);

    // Use API-provided lists directly
    final fertilizers = List<String>.from(json['fertilizers'] ?? []);
    final pesticides = List<String>.from(json['pesticides'] ?? []);
    final carePoints = List<String>.from(json['care_points'] ?? []);

    // If API provides empty lists, use fallback recommendations
    final useFallback =
        fertilizers.isEmpty && pesticides.isEmpty && carePoints.isEmpty;
    final fallback = useFallback ? _getTreatment(diseaseName) : null;

    String severity = 'Low';
    if (confidence >= 0.8) {
      severity = 'High';
    } else if (confidence >= 0.5) {
      severity = 'Moderate';
    }

    return DetectionResult(
      diseaseName: diseaseName,
      confidence: confidence,
      severity: severity,
      fertilizers: fertilizers.isNotEmpty
          ? fertilizers
          : (fallback?['fertilizers'] ?? []),
      pesticides:
          pesticides.isNotEmpty ? pesticides : (fallback?['pesticides'] ?? []),
      actionSteps:
          carePoints.isNotEmpty ? carePoints : (fallback?['steps'] ?? []),
      description: json['description'] as String? ??
          (fallback?['description']?.first ?? ''),
      imageUrl: imageUrl,
      originalImageUrl: originalImageUrl,
      predictedImageUrl: predictedImageUrl,
      predictionText: topPredictionText,
      products: (json['products'] as List?)
              ?.map((p) =>
                  ProductRecommendation.fromJson(Map<String, dynamic>.from(p)))
              .toList() ??
          const <ProductRecommendation>[],
    );
  }

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('disease') || json.containsKey('prediction')) {
      return DetectionResult.fromApiResponse(json);
    }
    return DetectionResult(
      diseaseName: json['disease_name'] ?? json['class'] ?? 'Unknown',
      confidence:
          _normalizeConfidence(json['confidence'] ?? json['probability'] ?? 0),
      severity: json['severity'] ?? 'Medium',
      fertilizers: List<String>.from(json['fertilizers'] ?? []),
      pesticides: List<String>.from(json['pesticides'] ?? []),
      actionSteps:
          List<String>.from(json['action_steps'] ?? json['care_points'] ?? []),
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      originalImageUrl: json['original_image'],
      predictedImageUrl: json['predicted_image'],
      predictionText: _topPredictionText(json['prediction']?.toString() ?? ''),
      products: (json['products'] as List?)
              ?.map((p) =>
                  ProductRecommendation.fromJson(Map<String, dynamic>.from(p)))
              .toList() ??
          const <ProductRecommendation>[],
    );
  }

  DetectionResult copyWith({
    String? diseaseName,
    double? confidence,
    String? severity,
    List<String>? fertilizers,
    List<String>? pesticides,
    List<String>? actionSteps,
    String? description,
    String? imageUrl,
    String? originalImageUrl,
    String? predictedImageUrl,
    String? predictionText,
    List<ProductRecommendation>? products,
  }) =>
      DetectionResult(
        diseaseName: diseaseName ?? this.diseaseName,
        confidence: confidence ?? this.confidence,
        severity: severity ?? this.severity,
        fertilizers: fertilizers ?? this.fertilizers,
        pesticides: pesticides ?? this.pesticides,
        actionSteps: actionSteps ?? this.actionSteps,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        originalImageUrl: originalImageUrl ?? this.originalImageUrl,
        predictedImageUrl: predictedImageUrl ?? this.predictedImageUrl,
        predictionText: predictionText ?? this.predictionText,
        products: products ?? this.products,
      );

  DetectionResult mergePredictionHistory(PredictionHistoryItem history) {
    return copyWith(
      diseaseName:
          diseaseName.trim().isNotEmpty ? diseaseName : (history.disease ?? ''),
      fertilizers: fertilizers.isNotEmpty ? fertilizers : history.fertilizers,
      pesticides: pesticides.isNotEmpty ? pesticides : history.pesticides,
      actionSteps: actionSteps.isNotEmpty ? actionSteps : history.carePoints,
      imageUrl: imageUrl ?? history.predictedImageUrl ?? history.imageUrl,
      originalImageUrl: originalImageUrl ?? history.originalImageUrl,
      predictedImageUrl: predictedImageUrl ?? history.predictedImageUrl,
      predictionText: predictionText.trim().isNotEmpty
          ? predictionText
          : _topPredictionText(history.prediction),
      products: products.isNotEmpty ? products : history.products,
    );
  }

  bool get isHealthy {
    final l = diseaseName.trim().toLowerCase();
    if (l.isEmpty) return false;
    if (l.contains('unhealthy')) return false;
    return l == 'healthy' ||
        l.startsWith('healthy ') ||
        l.contains(' healthy ') ||
        l.contains('no disease') ||
        l.contains('no_detection') ||
        l.contains('no detection');
  }

  static MapEntry<String, double>? _parseTopPrediction(String predictionRaw) {
    if (predictionRaw.trim().isEmpty) return null;

    final lines = predictionRaw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    String? bestDisease;
    double bestScore = -1.0;
    final pattern = RegExp(r'^(.+?)\s*\(([\d.]+)%?\)\s*$');

    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match == null) continue;
      final disease = match.group(1)!.replaceAll('_', ' ').trim();
      final score = _normalizeConfidence(match.group(2));
      if (disease.isEmpty) continue;
      if (score > bestScore) {
        bestScore = score;
        bestDisease = disease;
      }
    }

    if (bestDisease == null) return null;
    return MapEntry(bestDisease, bestScore.clamp(0.0, 1.0));
  }

  static String _topPredictionText(
    String predictionRaw, [
    MapEntry<String, double>? parsedTop,
  ]) {
    final normalized = predictionRaw.trim();
    if (normalized.isEmpty) return '';

    final top = parsedTop ?? _parseTopPrediction(normalized);
    if (top == null) {
      return normalized.split('\n').map((line) => line.trim()).firstWhere(
            (line) => line.isNotEmpty,
            orElse: () => normalized,
          );
    }

    return '${top.key} (${top.value.toStringAsFixed(2)})';
  }

  static bool _isGenericDiseaseLabel(String rawValue) {
    final normalized =
        rawValue.trim().toLowerCase().replaceAll('_', ' ').trim();
    return normalized.isEmpty ||
        normalized == 'healthy' ||
        normalized == 'unhealthy' ||
        normalized == 'diseased' ||
        normalized == 'disease' ||
        normalized == 'no detection' ||
        normalized == 'no disease detected';
  }

  static double _normalizeConfidence(dynamic rawValue) {
    if (rawValue == null) return 0.0;
    final parsed = double.tryParse(rawValue.toString().trim()) ?? 0.0;
    if (parsed <= 0) return 0.0;
    if (parsed > 1.0) {
      return (parsed / 100).clamp(0.0, 1.0);
    }
    return parsed.clamp(0.0, 1.0);
  }

  static Map<String, List<String>> _getTreatment(String disease) {
    final d = disease.toLowerCase();
    if ((d.contains('healthy') && !d.contains('unhealthy')) ||
        d.contains('no disease') ||
        d.contains('no detection')) {
      return {
        'fertilizers': [
          'Continue regular NPK fertilization',
          'Maintain soil pH 6.0-7.0'
        ],
        'pesticides': ['No pesticide needed'],
        'steps': [
          'Continue current care routine',
          'Monitor weekly',
          'Maintain proper watering'
        ],
        'description': [
          'Your crop appears healthy. Continue regular maintenance.'
        ],
      };
    }
    if (d.contains('blight')) {
      return {
        'fertilizers': ['NPK 20-20-20 (2g/L)', 'Calcium Nitrate spray (3g/L)'],
        'pesticides': ['Mancozeb 75WP (2.5g/L)', 'Copper Oxychloride (3g/L)'],
        'steps': [
          'Remove infected leaves immediately',
          'Apply fungicide every 7 days',
          'Avoid overhead irrigation',
          'Improve air circulation',
          'Monitor for 2 weeks'
        ],
        'description': [
          'Blight is a fungal disease. Act quickly to prevent spread.'
        ],
      };
    }
    if (d.contains('bacterial') || d.contains('canker')) {
      return {
        'fertilizers': [
          'Potassium-rich fertilizer (3g/L)',
          'Avoid excess nitrogen'
        ],
        'pesticides': [
          'Copper-based bactericide (3g/L)',
          'Streptomycin sulfate spray'
        ],
        'steps': [
          'Remove infected plant parts',
          'Disinfect tools after use',
          'Apply copper bactericide weekly',
          'Avoid wetting foliage'
        ],
        'description': ['Bacterial disease spreads through water and wounds.'],
      };
    }
    if (d.contains('virus') || d.contains('curl') || d.contains('mosaic')) {
      return {
        'fertilizers': ['Balanced NPK', 'Boron micronutrient (0.5g/L)'],
        'pesticides': [
          'Imidacloprid (0.5ml/L) for whitefly',
          'Neem oil spray (5ml/L)'
        ],
        'steps': [
          'Remove infected plants',
          'Control insect vectors',
          'Use reflective mulch',
          'Plant resistant varieties'
        ],
        'description': [
          'Viral diseases spread by insects. Control vectors immediately.'
        ],
      };
    }
    if (d.contains('pest') ||
        d.contains('borer') ||
        d.contains('fly') ||
        d.contains('bug')) {
      return {
        'fertilizers': [
          'Balanced NPK',
          'Silicon supplement to strengthen plant'
        ],
        'pesticides': [
          'Spinosad (1ml/L)',
          'Neem oil (10ml/L)',
          'Chlorpyrifos (2ml/L)'
        ],
        'steps': [
          'Remove pests manually',
          'Apply insecticide in evening',
          'Use pheromone traps',
          'Cover crops with nets'
        ],
        'description': [
          'Insect pests cause physical damage. Early detection is essential.'
        ],
      };
    }
    return {
      'fertilizers': ['Balanced NPK fertilizer (2g/L)', 'Micronutrient spray'],
      'pesticides': [
        'Broad-spectrum fungicide (2g/L)',
        'Neem oil spray (5ml/L)'
      ],
      'steps': [
        'Consult local agricultural extension officer',
        'Remove visibly infected plant parts',
        'Apply recommended treatment',
        'Monitor plant health weekly'
      ],
      'description': [
        'Disease detected. Apply the recommended treatment and monitor closely.'
      ],
    };
  }
}

// ==================== GET PRODUCT MODEL ====================

class CropProduct {
  final String cropTitle;
  final List<DiseaseProduct> diseases;

  CropProduct({required this.cropTitle, required this.diseases});

  factory CropProduct.fromJson(Map<String, dynamic> json) {
    return CropProduct(
      cropTitle: (json['title']?.toString() ?? '').trim(),
      diseases: ((json['products'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => DiseaseProduct.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DiseaseProduct {
  final String diseaseName;
  final List<ProductItem> products;

  DiseaseProduct({
    required this.diseaseName,
    required this.products,
  });

  factory DiseaseProduct.fromJson(Map<String, dynamic> json) {
    return DiseaseProduct(
      diseaseName: (json['disease_name']?.toString() ?? '').trim(),
      products: ((json['products'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => ProductItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ProductItem {
  final String name;
  final String image;
  final String url;

  ProductItem({
    required this.name,
    required this.image,
    required this.url,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      name: (json['product_name']?.toString() ?? '').trim(),
      image: (json['product_image']?.toString() ?? '').trim(),
      url: (json['product_url']?.toString() ?? '').trim(),
    );
  }
}

// ==================== FARMING TIP MODEL ====================
class FarmingTip {
  final int id;

  final String title;

  final String description;

  FarmingTip({
    required this.id,
    required this.title,
    required this.description,
  });

  factory FarmingTip.fromJson(Map<String, dynamic> json) {
    return FarmingTip(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      description: json['description'] ?? "",
    );
  }
}

// ==================== NOTIFICATION MODEL ====================
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  String get emoji {
    switch (type) {
      case 'rain':
        return '🌧️';
      case 'disease':
        return '⚠️';
      case 'fertilizer':
        return '🌱';
      default:
        return '📢';
    }
  }
}
