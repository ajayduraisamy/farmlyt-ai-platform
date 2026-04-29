class AppConstants {
  static const String appName = 'Farmlyt AI';
  static const String tagline = 'Smart Farming with AI Insights';

  static const String baseUrl =
      'https://aislynajay-leaf-disease-detection.hf.space';
  static const String productionBaseUrl =
      'https://aislynajay-product-development.hf.space';
  static const String weatherBaseUrl = 'https://api.open-meteo.com/v1';

  // Auth Endpoints
  static const String registerEndpoint = '/api/register';
  static const String loginEndpoint = '/api/login';

  // Production API Endpoints
  static const String getFarmingTipsEndpoint = '/get_farming_tips';
  static const String getAgriTitlesEndpoint = '/get_agri_titles';
  static const String getCropsEndpoint = '/get_crops';
  static const String getCropSubEndpoint = '/get_crop_sub';
  static const String getLeafPredictionsEndpoint = '/get_leaf_predictions';
  static const String updateProfileEndpoint = '/auth/update-profile';

  // Payment Endpoints
  static const String createOrderEndpoint = '/create-order';
  static const String verifyPaymentEndpoint = '/verify-payment';

  // Razorpay key can come from backend create-order response or build-time env.
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID',
      defaultValue: 'rzp_live_ShfATQHJSWgRSA');

  // SharedPrefs Keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserPhone = 'user_phone';
  static const String keyUserEmail = 'user_email';
  static const String keyCredits = 'user_credits';
  static const String keyUserProfileImagePath = 'user_profile_image_path';
  static const String keyLanguage = 'selected_language';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyIsFirstTime = 'is_first_time';

  // Credits
  static const int initialCredits = 50;
  static const int creditsPerScan = 10;

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 60000;

  // Broad cloud-translation language fallback list.
  // This covers the common Google Cloud Translation target languages we expose
  // in the selector even before the live language API is fetched.
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية', 'flag': '🇸🇦'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা', 'flag': '🇧🇩'},
    {'code': 'bg', 'name': 'Bulgarian', 'native': 'Български', 'flag': '🇧🇬'},
    {'code': 'ca', 'name': 'Catalan', 'native': 'Català', 'flag': '🇪🇸'},
    {'code': 'zh', 'name': 'Chinese', 'native': '中文', 'flag': '🇨🇳'},
    {'code': 'hr', 'name': 'Croatian', 'native': 'Hrvatski', 'flag': '🇭🇷'},
    {'code': 'cs', 'name': 'Czech', 'native': 'Čeština', 'flag': '🇨🇿'},
    {'code': 'da', 'name': 'Danish', 'native': 'Dansk', 'flag': '🇩🇰'},
    {'code': 'nl', 'name': 'Dutch', 'native': 'Nederlands', 'flag': '🇳🇱'},
    {'code': 'et', 'name': 'Estonian', 'native': 'Eesti', 'flag': '🇪🇪'},
    {'code': 'fi', 'name': 'Finnish', 'native': 'Suomi', 'flag': '🇫🇮'},
    {'code': 'fr', 'name': 'French', 'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'el', 'name': 'Greek', 'native': 'Ελληνικά', 'flag': '🇬🇷'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી', 'flag': '🇮🇳'},
    {'code': 'he', 'name': 'Hebrew', 'native': 'עברית', 'flag': '🇮🇱'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'hu', 'name': 'Hungarian', 'native': 'Magyar', 'flag': '🇭🇺'},
    {'code': 'is', 'name': 'Icelandic', 'native': 'Íslenska', 'flag': '🇮🇸'},
    {
      'code': 'id',
      'name': 'Indonesian',
      'native': 'Bahasa Indonesia',
      'flag': '🇮🇩'
    },
    {'code': 'it', 'name': 'Italian', 'native': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'ja', 'name': 'Japanese', 'native': '日本語', 'flag': '🇯🇵'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
    {'code': 'ko', 'name': 'Korean', 'native': '한국어', 'flag': '🇰🇷'},
    {'code': 'lv', 'name': 'Latvian', 'native': 'Latviešu', 'flag': '🇱🇻'},
    {'code': 'lt', 'name': 'Lithuanian', 'native': 'Lietuvių', 'flag': '🇱🇹'},
    {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം', 'flag': '🇮🇳'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी', 'flag': '🇮🇳'},
    {'code': 'no', 'name': 'Norwegian', 'native': 'Norsk', 'flag': '🇳🇴'},
    {'code': 'fa', 'name': 'Persian', 'native': 'فارسی', 'flag': '🇮🇷'},
    {'code': 'pl', 'name': 'Polish', 'native': 'Polski', 'flag': '🇵🇱'},
    {'code': 'pt', 'name': 'Portuguese', 'native': 'Português', 'flag': '🇵🇹'},
    {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
    {'code': 'ro', 'name': 'Romanian', 'native': 'Română', 'flag': '🇷🇴'},
    {'code': 'ru', 'name': 'Russian', 'native': 'Русский', 'flag': '🇷🇺'},
    {'code': 'sk', 'name': 'Slovak', 'native': 'Slovenčina', 'flag': '🇸🇰'},
    {
      'code': 'sl',
      'name': 'Slovenian',
      'native': 'Slovenščina',
      'flag': '🇸🇮'
    },
    {'code': 'es', 'name': 'Spanish', 'native': 'Español', 'flag': '🇪🇸'},
    {'code': 'sw', 'name': 'Swahili', 'native': 'Kiswahili', 'flag': '🇹🇿'},
    {'code': 'sv', 'name': 'Swedish', 'native': 'Svenska', 'flag': '🇸🇪'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🇮🇳'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు', 'flag': '🇮🇳'},
    {'code': 'th', 'name': 'Thai', 'native': 'ไทย', 'flag': '🇹🇭'},
    {'code': 'tr', 'name': 'Turkish', 'native': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'uk', 'name': 'Ukrainian', 'native': 'Українська', 'flag': '🇺🇦'},
    {'code': 'ur', 'name': 'Urdu', 'native': 'اردو', 'flag': '🇵🇰'},
    {
      'code': 'vi',
      'name': 'Vietnamese',
      'native': 'Tiếng Việt',
      'flag': '🇻🇳'
    },
    {'code': 'zu', 'name': 'Zulu', 'native': 'isiZulu', 'flag': '🇿🇦'},
  ];

  static final List<String> supportedLanguageCodes = supportedLanguages
      .map((language) => language['code']!)
      .toList(growable: false);

  // Credit packages: { credits, priceInr, label }
  static const List<Map<String, dynamic>> creditPackages = [
    {'credits': 29, 'priceInr': 29, 'label': '₹29', 'popular': false},
    {'credits': 49, 'priceInr': 49, 'label': '₹49', 'popular': true},
    {'credits': 89, 'priceInr': 89, 'label': '₹89', 'popular': false},
    {'credits': 199, 'priceInr': 199, 'label': '₹199', 'popular': false},
  ];

  /// Build ordered detection endpoint candidates from category and cropKey.
  static List<String> getDetectionEndpoints(String category, String cropKey) {
    final normalizedCategory = normalizeCategoryId(category);
    final candidates = <String>[];
    final cropKeys = _endpointCropKeyCandidates(normalizedCategory, cropKey);

    void add(String path) {
      if (path.trim().isEmpty || candidates.contains(path)) return;
      candidates.add(path);
    }

    for (final crop in cropKeys) {
      switch (normalizedCategory) {
        case 'leaf':
          add('/leafs/$crop');
          add('/leaf/$crop');
          break;
        case 'fruit':
          add('/fruits/$crop');
          add('/fruit/$crop');
          break;
        case 'vegetable':
          add('/vegtables/$crop'); // Backend spelling: vegtables
          add('/vegetables/$crop');
          add('/vegetable/$crop');
          add('/vegitable/$crop');
          break;
        case 'flower':
          add('/flowers/$crop');
          add('/flower/$crop');
          break;
        case 'soil':
          add('/soil/$crop');
          add('/soils/$crop');
          break;
        default:
          final cleanedCategory = category.trim().toLowerCase();
          add('/$cleanedCategory/$crop');
          add('/${cleanedCategory}s/$crop');
          break;
      }
    }

    return candidates;
  }

  static String getDetectionEndpoint(String category, String cropKey) =>
      getDetectionEndpoints(category, cropKey).first;

  static const Map<String, String> categoryIcons = {
    'leaf': '🍃',
    'leafs': '🍃',
    'fruit': '🍋',
    'fruits': '🍋',
    'flower': '🌸',
    'flowers': '🌸',
    'vegetable': '🥦',
    'vegtables': '🥦',
    'vegetables': '🥦',
    'soil': '🟫',
    'plant': '🌿',
  };

  static const Map<String, int> categoryColors = {
    'leaf': 0xFF2E7D32,
    'leafs': 0xFF2E7D32,
    'fruit': 0xFFFF8F00,
    'fruits': 0xFFFF8F00,
    'flower': 0xFFAD1457,
    'flowers': 0xFFAD1457,
    'vegetable': 0xFF00695C,
    'vegtables': 0xFF00695C,
    'vegetables': 0xFF00695C,
    'soil': 0xFF4E342E,
    'plant': 0xFF2E7D32,
  };

  static String normalizeCategoryId(String apiKey) {
    final normalized = apiKey.trim().toLowerCase();
    switch (normalized) {
      case 'leafs':
      case 'leaves':
        return 'leaf';
      case 'fruits':
        return 'fruit';
      case 'flowers':
        return 'flower';
      case 'vegtables':
      case 'vegitable':
      case 'vegetables':
        return 'vegetable';
      default:
        if (normalized.contains('leaf')) return 'leaf';
        if (normalized.contains('fruit')) return 'fruit';
        if (normalized.contains('flower')) return 'flower';
        if (normalized.contains('veg')) return 'vegetable';
        return normalized;
    }
  }

  static String categoryToApiPath(String categoryId) {
    switch (categoryId) {
      case 'leaf':
        return 'leafs';
      case 'fruit':
        return 'fruits';
      case 'flower':
        return 'flowers';
      case 'vegetable':
        return 'vegtables';
      default:
        return categoryId;
    }
  }

  static String _normalizeEndpointCropKey(String cropKey) {
    // Replace spaces with underscores for backend compatibility
    final normalized = cropKey.trim().toLowerCase().replaceAll(' ', '_');

    // Explicit mappings for specific backend differences
    const aliases = <String, String>{
      'chilli': 'chili',
      'lady_finger': 'ladyfinger',
      'tomato_fruit': 'tomato',
      'brinjal_veg': 'brinjal',
      'brinjal_vegetable': 'brinjal',
      'ridge_gourd': 'ridge',
      'bitter_gourd': 'bitter_gourd',
      'chrysanthemum': 'chrysanthemums', // Pluralized in backend
    };

    return aliases[normalized] ?? normalized;
  }

  static List<String> _endpointCropKeyCandidates(
    String normalizedCategory,
    String cropKey,
  ) {
    final normalized = cropKey.trim().toLowerCase().replaceAll(' ', '_');
    final primary = _normalizeEndpointCropKey(cropKey);
    final candidates = <String>[];

    void add(String value) {
      final cleaned = value.trim();
      if (cleaned.isEmpty || candidates.contains(cleaned)) return;
      candidates.add(cleaned);
    }

    add(primary);

    if (normalizedCategory == 'fruit') {
      if (normalized == 'tomato_fruit') add('tomato_fruit');
      if (primary == 'tomato') add('tomato_fruit');
    }

    if (normalizedCategory == 'vegetable') {
      if (normalized == 'brinjal_veg' || normalized == 'brinjal_vegetable') {
        add(normalized);
      }
      if (primary == 'brinjal') add('brinjal_veg');
      if (primary == 'ridge') add('ridge_gourd');
      if (normalized == 'ridge_gourd') add('ridge');
    }

    if (normalizedCategory == 'flower') {
      if (normalized == 'chrysanthemum') add('chrysanthemum');
      if (primary == 'chrysanthemums') add('chrysanthemum');
      if (primary == 'chrysanthemum') add('chrysanthemums');
    }

    return candidates;
  }
}
