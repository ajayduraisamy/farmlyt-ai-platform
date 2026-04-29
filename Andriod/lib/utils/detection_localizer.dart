import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

class DetectionLocalizer {
  static String categoryTitle(
    BuildContext context,
    String categoryId, {
    String? fallbackTitle,
  }) {
    final l = AppLocalizations.of(context);
    switch (categoryId) {
      case 'leaf':
        return l.t('leaf_detection_title');
      case 'fruit':
        return l.t('fruit_detection_title');
      case 'flower':
        return l.t('flower_analysis_title');
      case 'vegetable':
        return l.t('vegetable_detection_title');
      case 'soil':
        return l.t('soil_detection_title');
      default:
        final trimmedFallback = fallbackTitle?.trim();
        return trimmedFallback != null && trimmedFallback.isNotEmpty
            ? trimmedFallback
            : l.diseaseDetection;
    }
  }

  static List<String> categoryCrops(BuildContext context, String categoryId) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ta') {
      return _taCrops[categoryId] ?? _enCrops[categoryId] ?? const <String>[];
    }
    if (code == 'kn') {
      return _knCrops[categoryId] ?? _enCrops[categoryId] ?? const <String>[];
    }
    if (code == 'hi') {
      return _hiCrops[categoryId] ?? _enCrops[categoryId] ?? const <String>[];
    }
    if (code == 'te') {
      return _teCrops[categoryId] ?? _enCrops[categoryId] ?? const <String>[];
    }
    if (code == 'ml') {
      return _mlCrops[categoryId] ?? _enCrops[categoryId] ?? const <String>[];
    }
    return _enCrops[categoryId] ?? const <String>[];
  }

  static String cropLabel(
    BuildContext context,
    String cropKey, {
    String? fallbackLabel,
  }) {
    final code = Localizations.localeOf(context).languageCode;
    final key = cropKey.trim().toLowerCase();
    final fallback = fallbackLabel?.trim();

    if (code == 'ta') {
      return _taCropNames[key] ??
          _enCropNames[key] ??
          (fallback != null && fallback.isNotEmpty ? fallback : null) ??
          _titleizeCropKey(cropKey);
    }
    if (code == 'kn') {
      return _knCropNames[key] ??
          _enCropNames[key] ??
          (fallback != null && fallback.isNotEmpty ? fallback : null) ??
          _titleizeCropKey(cropKey);
    }
    if (code == 'hi') {
      return _hiCropNames[key] ??
          _enCropNames[key] ??
          (fallback != null && fallback.isNotEmpty ? fallback : null) ??
          _titleizeCropKey(cropKey);
    }
    if (code == 'te') {
      return _teCropNames[key] ??
          _enCropNames[key] ??
          (fallback != null && fallback.isNotEmpty ? fallback : null) ??
          _titleizeCropKey(cropKey);
    }
    if (code == 'ml') {
      return _mlCropNames[key] ??
          _enCropNames[key] ??
          (fallback != null && fallback.isNotEmpty ? fallback : null) ??
          _titleizeCropKey(cropKey);
    }

    return _enCropNames[key] ??
        (fallback != null && fallback.isNotEmpty ? fallback : null) ??
        _titleizeCropKey(cropKey);
  }

  static String _titleizeCropKey(String cropKey) => cropKey
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  static const Map<String, List<String>> _enCrops = {
    'leaf': <String>['Tomato', 'Potato', 'Brinjal', 'Chili', 'Lady Finger'],
    'fruit': <String>[
      'Custard Apple',
      'Guava',
      'Pomegranate',
      'Lemon',
      'Tomato',
    ],
    'flower': <String>['Rose', 'Marigold', 'Chrysanthemums'],
    'vegetable': <String>[
      'Brinjal',
      'Cauliflower',
      'Cucumber',
      'Ridge',
    ],
    'soil': <String>[],
  };

  static const Map<String, List<String>> _taCrops = {
    'leaf': <String>[
      'தக்காளி',
      'உருளைக்கிழங்கு',
      'கத்திரிக்காய்',
      'மிளகாய்',
      'வெண்டைக்காய்'
    ],
    'fruit': <String>['சீதாப்பழம்', 'கொய்யா', 'மாதுளை', 'எலுமிச்சை', 'தக்காளி'],
    'flower': <String>['ரோஜா', 'சாமந்தி', 'சேவந்தி'],
    'vegetable': <String>[
      'கத்திரிக்காய்',
      'பூக்கோசு',
      'வெள்ளரிக்காய்',
      'பீர்க்கங்காய்',
    ],
    'soil': <String>[],
  };

  static const Map<String, List<String>> _knCrops = {
    'leaf': <String>[
      'ಟೊಮೇಟೊ',
      'ಆಲೂಗಡ್ಡೆ',
      'ಬದನೆಕಾಯಿ',
      'ಮೆಣಸಿನಕಾಯಿ',
      'ಬೆಂಡೆಕಾಯಿ'
    ],
    'fruit': <String>['ಸೀತಾಫಲ', 'ಸೀಬೆಹಣ್ಣು', 'ದಾಳಿಂಬೆ', 'ನಿಂಬೆ', 'ಟೊಮೇಟೊ'],
    'flower': <String>['ಗುಲಾಬಿ', 'ಚೆಂಡುಹೂವು', 'ಶೆವಂತಿಗೆ'],
    'vegetable': <String>[
      'ಬದನೆಕಾಯಿ',
      'ಕೋಸುಹೂವು',
      'ಸೌತೆಕಾಯಿ',
      'ಹೀರೇಕಾಯಿ',
    ],
    'soil': <String>[],
  };

  static const Map<String, List<String>> _hiCrops = {
    'leaf': <String>['टमाटर', 'आलू', 'बैंगन', 'मिर्च', 'भिंडी'],
    'fruit': <String>['सीताफल', 'अमरूद', 'अनार', 'नींबू', 'टमाटर'],
    'flower': <String>['गुलाब', 'गेंदा', 'गुलदाउदी'],
    'vegetable': <String>[
      'बैंगन',
      'फूलगोभी',
      'खीरा',
      'तुरई',
    ],
    'soil': <String>[],
  };

  static const Map<String, List<String>> _teCrops = {
    'leaf': <String>['టమాటా', 'బంగాళదుంప', 'వంకాయ', 'మిరపకాయ', 'బెండకాయ'],
    'fruit': <String>['సీతాఫలం', 'జామ', 'దానిమ్మ', 'నిమ్మకాయ', 'టమాటా'],
    'flower': <String>['గులాబీ', 'బంతి', 'చామంతి'],
    'vegetable': <String>[
      'వంకాయ',
      'కాలీఫ్లవర్',
      'దోసకాయ',
      'బీరకాయ',
    ],
    'soil': <String>[],
  };

  static const Map<String, List<String>> _mlCrops = {
    'leaf': <String>[
      'തക്കാളി',
      'ഉരുളക്കിഴങ്ങ്',
      'വഴുതന',
      'മുളക്',
      'വെണ്ടയ്ക്ക'
    ],
    'fruit': <String>[
      'സീതപ്പഴം',
      'പേരയ്ക്ക',
      'മാതളനാരങ്ങ',
      'നാരങ്ങ',
      'തക്കാളി'
    ],
    'flower': <String>['റോസ്', 'ചെണ്ടുമല്ലി', 'ശെവന്തി'],
    'vegetable': <String>[
      'വഴുതന',
      'കോളിഫ്ലവർ',
      'വെള്ളരിക്ക',
      'പീരയ്ക്ക',
    ],
    'soil': <String>[],
  };

  static const Map<String, String> _enCropNames = {
    'tomato': 'Tomato',
    'potato': 'Potato',
    'brinjal': 'Brinjal',
    'chili': 'Chili',
    'ladyfinger': 'Lady Finger',
    'pomegranate': 'Pomegranate',
    'lemon': 'Lemon',
    'guava': 'Guava',
    'custard_apple': 'Custard Apple',
    'jasmine': 'Jasmine',
    'rose': 'Rose',
    'chrysanthemum': 'Chrysanthemum',
    'chrysanthemums': 'Chrysanthemums',
    'roses': 'Roses',
    'marigold': 'Marigold',
    'ridge': 'Ridge',
    'ridge_gourd': 'Ridge Gourd',
    'cauliflower': 'Cauliflower',
    'cucumber': 'Cucumber',
    'bitter_gourd': 'Bitter Gourd',
  };

  static const Map<String, String> _taCropNames = {
    'tomato': 'தக்காளி',
    'potato': 'உருளைக்கிழங்கு',
    'brinjal': 'கத்திரிக்காய்',
    'chili': 'மிளகாய்',
    'ladyfinger': 'வெண்டைக்காய்',
    'pomegranate': 'மாதுளை',
    'lemon': 'எலுமிச்சை',
    'guava': 'கொய்யா',
    'custard_apple': 'சீதாப்பழம்',
    'jasmine': 'மல்லிகை',
    'rose': 'ரோஜா',
    'chrysanthemum': 'சேவந்தி',
    'chrysanthemums': 'சேவந்தி',
    'roses': 'ரோஜா',
    'marigold': 'சாமந்தி',
    'ridge': 'பீர்க்கங்காய்',
    'ridge_gourd': 'பீர்க்கங்காய்',
    'cauliflower': 'பூக்கோசு',
    'cucumber': 'வெள்ளரிக்காய்',
    'bitter_gourd': 'பாகற்காய்',
  };

  static const Map<String, String> _knCropNames = {
    'tomato': 'ಟೊಮೇಟೊ',
    'potato': 'ಆಲೂಗಡ್ಡೆ',
    'brinjal': 'ಬದನೆಕಾಯಿ',
    'chili': 'ಮೆಣಸಿನಕಾಯಿ',
    'ladyfinger': 'ಬೆಂಡೆಕಾಯಿ',
    'pomegranate': 'ದಾಳಿಂಬೆ',
    'lemon': 'ನಿಂಬೆ',
    'guava': 'ಸೀಬೆಹಣ್ಣು',
    'custard_apple': 'ಸೀತಾಫಲ',
    'jasmine': 'ಮಲ್ಲಿಗೆ',
    'rose': 'ಗುಲಾಬಿ',
    'chrysanthemum': 'ಶೆವಂತಿಗೆ',
    'chrysanthemums': 'ಶೆವಂತಿಗೆ',
    'roses': 'ಗುಲಾಬಿ',
    'marigold': 'ಚೆಂಡುಹೂವು',
    'ridge': 'ಹೀರೇಕಾಯಿ',
    'ridge_gourd': 'ಹೀರೇಕಾಯಿ',
    'cauliflower': 'ಕೋಸುಹೂವು',
    'cucumber': 'ಸೌತೆಕಾಯಿ',
    'bitter_gourd': 'ಹಾಗಲಕಾಯಿ',
  };

  static const Map<String, String> _hiCropNames = {
    'tomato': 'टमाटर',
    'potato': 'आलू',
    'brinjal': 'बैंगन',
    'chili': 'मिर्च',
    'ladyfinger': 'भिंडी',
    'pomegranate': 'अनार',
    'lemon': 'नींबू',
    'guava': 'अमरूद',
    'custard_apple': 'सीताफल',
    'jasmine': 'चमेली',
    'rose': 'गुलाब',
    'chrysanthemum': 'गुलदाउदी',
    'chrysanthemums': 'गुलदाउदी',
    'roses': 'गुलाब',
    'marigold': 'गेंदा',
    'ridge': 'तुरई',
    'ridge_gourd': 'तुरई',
    'cauliflower': 'फूलगोभी',
    'cucumber': 'खीरा',
    'bitter_gourd': 'करेला',
  };

  static const Map<String, String> _teCropNames = {
    'tomato': 'టమాటా',
    'potato': 'బంగాళదుంప',
    'brinjal': 'వంకాయ',
    'chili': 'మిరపకాయ',
    'ladyfinger': 'బెండకాయ',
    'pomegranate': 'దానిమ్మ',
    'lemon': 'నిమ్మకాయ',
    'guava': 'జామ',
    'custard_apple': 'సీతాఫలం',
    'jasmine': 'మల్లె',
    'rose': 'గులాబీ',
    'chrysanthemum': 'చామంతి',
    'chrysanthemums': 'చామంతి',
    'roses': 'గులాబీ',
    'marigold': 'బంతి',
    'ridge': 'బీరకాయ',
    'ridge_gourd': 'బీరకాయ',
    'cauliflower': 'కాలీఫ్లవర్',
    'cucumber': 'దోసకాయ',
    'bitter_gourd': 'కాకరకాయ',
  };

  static const Map<String, String> _mlCropNames = {
    'tomato': 'തക്കാളി',
    'potato': 'ഉരുളക്കിഴങ്ങ്',
    'brinjal': 'വഴുതന',
    'chili': 'മുളക്',
    'ladyfinger': 'വെണ്ടയ്ക്ക',
    'pomegranate': 'മാതളനാരങ്ങ',
    'lemon': 'നാരങ്ങ',
    'guava': 'പേരയ്ക്ക',
    'custard_apple': 'സീതപ്പഴം',
    'jasmine': 'മുല്ല',
    'rose': 'റോസ്',
    'chrysanthemum': 'ശെവന്തി',
    'chrysanthemums': 'ശെവന്തി',
    'roses': 'റോസ്',
    'marigold': 'ചെണ്ടുമല്ലി',
    'ridge': 'പീരയ്ക്ക',
    'ridge_gourd': 'പീരയ്ക്ക',
    'cauliflower': 'കോളിഫ്ലവർ',
    'cucumber': 'വെള്ളരിക്ക',
    'bitter_gourd': 'പാവയ്ക്ക',
  };

  static String localizeDiseaseName(BuildContext context, String diseaseName) {
    final code = Localizations.localeOf(context).languageCode;
    final key = diseaseName.trim().toLowerCase();
    final spacedKey = key.replaceAll('_', ' ');

    String? lookup(Map<String, String> entries) =>
        entries[key] ?? entries[spacedKey];

    if (code == 'ta') {
      return lookup(_taDiseaseNames) ?? _titleizeCropKey(diseaseName);
    }
    if (code == 'kn') {
      return lookup(_knDiseaseNames) ?? _titleizeCropKey(diseaseName);
    }
    if (code == 'hi') {
      return lookup(_hiDiseaseNames) ?? _titleizeCropKey(diseaseName);
    }
    if (code == 'te') {
      return lookup(_teDiseaseNames) ?? _titleizeCropKey(diseaseName);
    }
    if (code == 'ml') {
      return lookup(_mlDiseaseNames) ?? _titleizeCropKey(diseaseName);
    }
    return _titleizeCropKey(diseaseName);
  }

  static String localizeRecommendationText(BuildContext context, String text) {
    final code = Localizations.localeOf(context).languageCode;
    final normalized = text.trim();
    final canonical = _recommendationAliases[normalized] ?? normalized;

    if (code == 'ta') {
      return _taRecommendations[canonical] ??
          _taRecommendations[normalized] ??
          normalized;
    }
    if (code == 'kn') {
      return _knRecommendations[canonical] ??
          _knRecommendations[normalized] ??
          normalized;
    }
    if (code == 'hi') {
      return _hiRecommendations[canonical] ??
          _hiRecommendations[normalized] ??
          normalized;
    }
    if (code == 'te') {
      return _teRecommendations[canonical] ??
          _teRecommendations[normalized] ??
          normalized;
    }
    if (code == 'ml') {
      return _mlRecommendations[canonical] ??
          _mlRecommendations[normalized] ??
          normalized;
    }

    return normalized;
  }

  static List<String> localizeRecommendationList(
      BuildContext context, List<String> items) {
    return items
        .map((item) => localizeRecommendationText(context, item))
        .toList();
  }

  static String localizePredictionText(BuildContext context, String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return '';
    }

    return lines.map((line) {
      final match = RegExp(r'^(.+?)\s*\(([\d.]+)\)$').firstMatch(line);
      if (match == null) {
        return localizeDiseaseName(context, line);
      }

      final disease = localizeDiseaseName(context, match.group(1)!.trim());
      final confidence = match.group(2)!;
      return '$disease ($confidence)';
    }).join('\n');
  }

  static const Map<String, String> _taDiseaseNames = {
    'no disease detected': 'நோய் கண்டறியப்படவில்லை',
    'no detection': 'நோய் கண்டறியப்படவில்லை',
    'healthy': 'ஆரோக்கியமானது',
    'late blight': 'தாமத பிளைட்',
    'early blight': 'ஆரம்ப பிளைட்',
    'bacterial spot': 'பாக்டீரியா புள்ளி நோய்',
    'bacterial canker': 'பாக்டீரியா காங்கர்',
    'leaf curl': 'இலை சுருட்டல்',
    'mosaic virus': 'மோசெயிக் வைரஸ்',
    'powdery mildew': 'தூள் பூஞ்சை',
    'downy mildew': 'டவுனி மில்டியூ',
    'leaf spot': 'இலை புள்ளி',
    'anthracnose': 'ஆன்த்ராக்னோஸ்',
    'root rot': 'வேர் அழுகல்',
    'wilt': 'வாடுதல்',
    'unhealthy': 'ஆரோக்கியமற்றது',
    'black spot': 'கருப்பு புள்ளி',
    'alternaria': 'அல்டர்நேரியா',
    'alternaria brassicae': 'அல்டர்நேரியா ப்ராசிக்கே',
    'citrus canker': 'சிட்ரஸ் காங்கர்',
    'bud rot': 'மொட்டு அழுகல்',
    'bud worm': 'மொட்டு புழு',
    'petal blight': 'இதழ் பிளைட்',
    'botrytis blight': 'போட்ரைடிஸ் பிளைட்',
    'septoria leaf spot': 'செப்டோரியா இலை புள்ளி',
    'fruit fly': 'பழ ஈ',
    'diplodia rot': 'டிப்ளோடியா அழுகல்',
    'blank canker': 'வெற்று காங்கர்',
  };

  static const Map<String, String> _knDiseaseNames = {
    'no disease detected': 'ರೋಗ ಪತ್ತೆಯಾಗಿಲ್ಲ',
    'no detection': 'ರೋಗ ಪತ್ತೆಯಾಗಿಲ್ಲ',
    'healthy': 'ಆರೋಗ್ಯಕರ',
    'late blight': 'ತಡ ಬ್ಲೈಟ್',
    'early blight': 'ಆರಂಭಿಕ ಬ್ಲೈಟ್',
    'bacterial spot': 'ಬ್ಯಾಕ್ಟೀರಿಯಾ ಕಲೆ ರೋಗ',
    'bacterial canker': 'ಬ್ಯಾಕ್ಟೀರಿಯಾ ಕ್ಯಾನ್ಕರ್',
    'leaf curl': 'ಎಲೆ ಮಡಿತ ರೋಗ',
    'mosaic virus': 'ಮೊಸಾಯಿಕ್ ವೈರಸ್',
    'powdery mildew': 'ಪುಡಿ ಮಿಲ್ಡ್ಯೂ',
    'downy mildew': 'ಡೌನಿ ಮಿಲ್ಡ್ಯೂ',
    'leaf spot': 'ಎಲೆ ಕಲೆ ರೋಗ',
    'anthracnose': 'ಆಂಥ್ರಾಕ್ನೋಸ್',
    'root rot': 'ಬೇರು ಕುಲುಷ',
    'wilt': 'ಒಣಗುವಿಕೆ ರೋಗ',
    'unhealthy': 'ಅನಾರೋಗ್ಯಕರ',
    'black spot': 'ಕಪ್ಪು ಕಲೆ',
    'alternaria': 'ಆಲ್ಟರ್ನೇರಿಯಾ',
    'alternaria brassicae': 'ಆಲ್ಟರ್ನೇರಿಯಾ ಬ್ರಾಸಿಕೇ',
    'citrus canker': 'ಸಿಟ್ರಸ್ ಕ್ಯಾನ್ಕರ್',
    'bud rot': 'ಮೊಗ್ಗು ಕುಲುಷ',
    'bud worm': 'ಮೊಗ್ಗು ಹುಳು',
    'petal blight': 'ದಳ ಬ್ಲೈಟ್',
    'botrytis blight': 'ಬೋಟ್ರೈಟಿಸ್ ಬ್ಲೈಟ್',
    'septoria leaf spot': 'ಸೆಪ್ಟೋರಿಯಾ ಎಲೆ ಕಲೆ',
    'fruit fly': 'ಹಣ್ಣು ಈ',
    'diplodia rot': 'ಡಿಪ್ಲೋಡಿಯಾ ಕುಲುಷ',
    'blank canker': 'ಬ್ಲ್ಯಾಂಕ್ ಕ್ಯಾನ್ಕರ್',
  };

  static const Map<String, String> _hiDiseaseNames = {
    'no disease detected': 'कोई रोग नहीं पाया गया',
    'no detection': 'कोई रोग नहीं पाया गया',
    'healthy': 'स्वस्थ',
    'late blight': 'लेट ब्लाइट',
    'early blight': 'अर्ली ब्लाइट',
    'bacterial spot': 'बैक्टीरियल स्पॉट',
    'bacterial canker': 'बैक्टीरियल कैंकर',
    'leaf curl': 'लीफ कर्ल',
    'mosaic virus': 'मोज़ेक वायरस',
    'powdery mildew': 'पाउडरी मिल्ड्यू',
    'downy mildew': 'डाउनी मिल्ड्यू',
    'leaf spot': 'लीफ स्पॉट',
    'anthracnose': 'एन्थ्रैक्नोज़',
    'root rot': 'जड़ सड़न',
    'wilt': 'मुरझाना',
    'unhealthy': 'अस्वस्थ',
    'black spot': 'काला धब्बा',
    'alternaria': 'अल्टरनेरिया',
    'alternaria brassicae': 'अल्टरनेरिया ब्रैसिकी',
    'citrus canker': 'सिट्रस कैंकर',
    'bud rot': 'कली सड़न',
    'bud worm': 'कली कीड़ा',
    'petal blight': 'पंखुड़ी ब्लाइट',
    'botrytis blight': 'बोट्राइटिस ब्लाइट',
    'septoria leaf spot': 'सेप्टोरिया लीफ स्पॉट',
    'fruit fly': 'फल मक्खी',
    'diplodia rot': 'डिप्लोडिया सड़न',
    'blank canker': 'ब्लैंक कैंकर',
  };

  static const Map<String, String> _teDiseaseNames = {
    'no disease detected': 'ఏ వ్యాధి గుర్తించబడలేదు',
    'no detection': 'ఏ వ్యాధి గుర్తించబడలేదు',
    'healthy': 'ఆరోగ్యకరమైనది',
    'late blight': 'లేట్ బ్లైట్',
    'early blight': 'ఎర్లీ బ్లైట్',
    'bacterial spot': 'బ్యాక్టీరియల్ స్పాట్',
    'bacterial canker': 'బ్యాక్టీరియల్ క్యాంకర్',
    'leaf curl': 'ఆకు ముడత',
    'mosaic virus': 'మోజైక్ వైరస్',
    'powdery mildew': 'పౌడరీ మిల్డ్యూ',
    'downy mildew': 'డౌనీ మిల్డ్యూ',
    'leaf spot': 'ఆకు మచ్చ',
    'anthracnose': 'ఆంత్రాక్నోస్',
    'root rot': 'వేరు కుళ్లు',
    'wilt': 'వాడిపోవడం',
    'unhealthy': 'అనారోగ్యకరమైనది',
    'black spot': 'నల్ల మచ్చ',
    'alternaria': 'ఆల్టర్నేరియా',
    'alternaria brassicae': 'ఆల్టర్నేరియా బ్రాసికే',
    'citrus canker': 'సిట్రస్ క్యాంకర్',
    'bud rot': 'మొగ్గ కుళ్లు',
    'bud worm': 'మొగ్గ పురుగు',
    'petal blight': 'రేకుల బ్లైట్',
    'botrytis blight': 'బోట్రిటిస్ బ్లైట్',
    'septoria leaf spot': 'సెప్టోరియా ఆకు మచ్చ',
    'fruit fly': 'పండు ఈగ',
    'diplodia rot': 'డిప్లోడియా కుళ్లు',
    'blank canker': 'బ్లాంక్ క్యాంకర్',
  };

  static const Map<String, String> _mlDiseaseNames = {
    'no disease detected': 'രോഗം കണ്ടെത്തിയില്ല',
    'no detection': 'രോഗം കണ്ടെത്തിയില്ല',
    'healthy': 'ആരോഗ്യമുള്ളത്',
    'late blight': 'ലേറ്റ് ബ്ലൈറ്റ്',
    'early blight': 'എർലി ബ്ലൈറ്റ്',
    'bacterial spot': 'ബാക്ടീരിയൽ സ്‌പോട്ട്',
    'bacterial canker': 'ബാക്ടീരിയൽ കാൻക്കർ',
    'leaf curl': 'ഇല ചുരുള്‍',
    'mosaic virus': 'മൊസായിക് വൈറസ്',
    'powdery mildew': 'പൗഡറി മിൽഡ്യൂ',
    'downy mildew': 'ഡൗണി മിൽഡ്യൂ',
    'leaf spot': 'ഇല പുള്ളി',
    'anthracnose': 'ആൻത്രാക്നോസ്',
    'root rot': 'വേർ ചെരിച്ചിൽ',
    'wilt': 'വാടൽ',
    'unhealthy': 'അസ്വാസ്ഥ്യമുള്ളത്',
    'black spot': 'കരിങ്കുത്ത്',
    'alternaria': 'ആൾട്ടർനേറിയ',
    'alternaria brassicae': 'ആൾട്ടർനേറിയ ബ്രാസിക്കേ',
    'citrus canker': 'സിട്രസ് കാൻക്കർ',
    'bud rot': 'മൊട്ട് ചെരിച്ചിൽ',
    'bud worm': 'മൊട്ട് പുഴു',
    'petal blight': 'ഇതൾ ബ്ലൈറ്റ്',
    'botrytis blight': 'ബോട്രൈറ്റിസ് ബ്ലൈറ്റ്',
    'septoria leaf spot': 'സെപ്ടോറിയ ഇല പുള്ളി',
    'fruit fly': 'പഴ ഈച്ച',
    'diplodia rot': 'ഡിപ്ലോഡിയ ചെരിച്ചിൽ',
    'blank canker': 'ബ്ലാങ്ക് കാൻക്കർ',
  };

  static const Map<String, String> _taRecommendations = {
    'Continue regular NPK fertilization': 'வழக்கமான NPK உரமிடலை தொடரவும்',
    'Maintain soil pH 6.0-7.0': 'மண்ணின் pH அளவை 6.0-7.0 ஆக பராமரிக்கவும்',
    'No pesticide needed': 'பூச்சிக்கொல்லி தேவையில்லை',
    'Continue current care routine': 'தற்போதைய பராமரிப்பு முறையை தொடரவும்',
    'Monitor weekly': 'வாரந்தோறும் கண்காணிக்கவும்',
    'Maintain proper watering': 'சரியான நீர்ப்பாசனத்தை பராமரிக்கவும்',
    'Your crop appears healthy. Continue regular maintenance.':
        'உங்கள் பயிர் ஆரோக்கியமாக உள்ளது. வழக்கமான பராமரிப்பை தொடரவும்.',
    'Calcium Nitrate spray (3g/L)': 'கால்சியம் நைட்ரேட் தெளிப்பு (3g/L)',
    'Remove and destroy infected leaves immediately':
        'பாதிக்கப்பட்ட இலைகளை உடனடியாக அகற்றி அழிக்கவும்',
    'Apply fungicide every 7 days':
        'ஒவ்வொரு 7 நாள்களிலும் பூஞ்சைநாசினி தெளிக்கவும்',
    'Avoid overhead irrigation': 'மேலிருந்து நீர் பாய்ச்சுவதை தவிர்க்கவும்',
    'Improve air circulation': 'காற்றோட்டத்தை மேம்படுத்தவும்',
    'Monitor for 2 weeks': '2 வாரங்கள் தொடர்ந்து கண்காணிக்கவும்',
    'Blight is a fungal disease causing dark spots with concentric rings. Act quickly to prevent spread.':
        'பிளைட் என்பது வளைய வடிவ கரும்புள்ளிகளை உருவாக்கும் பூஞ்சை நோய். பரவலைத் தடுக்க உடனே நடவடிக்கை எடுக்கவும்.',
    'Potassium-rich fertilizer (3g/L)': 'பொட்டாசியம் நிறைந்த உரம் (3g/L)',
    'Avoid excess nitrogen': 'அதிக நைட்ரஜன் பயன்பாட்டை தவிர்க்கவும்',
    'Copper-based bactericide (3g/L)':
        'செம்பு அடிப்படையிலான பாக்டீரியநாசினி (3g/L)',
    'Streptomycin sulfate spray': 'ஸ்ட்ரெப்டோமைசின் சல்பேட் தெளிப்பு',
    'Remove infected plant parts': 'பாதிக்கப்பட்ட செடி பகுதிகளை அகற்றவும்',
    'Disinfect tools after use':
        'பயன்பாட்டுக்கு பிறகு கருவிகளை நச்சுநீக்கம் செய்யவும்',
    'Apply copper bactericide weekly':
        'வாரத்திற்கு ஒருமுறை செம்பு பாக்டீரியநாசினி பயன்படுத்தவும்',
    'Avoid wetting foliage': 'இலைகள் நனைவதை தவிர்க்கவும்',
    'Isolate infected plants': 'பாதிக்கப்பட்ட செடிகளை தனிமைப்படுத்தவும்',
    'Bacterial disease spreads through water and wounds. Copper-based treatments are effective.':
        'பாக்டீரியா நோய் நீர் மற்றும் காயங்களின் மூலம் பரவும். செம்பு அடிப்படையிலான சிகிச்சை பயனுள்ளதாகும்.',
    'Balanced NPK': 'சமநிலை NPK உரம்',
    'Boron micronutrient (0.5g/L)': 'போரான் நுண்ணூட்டம் (0.5g/L)',
    'Imidacloprid (0.5ml/L) for whitefly control':
        'வைட்ஃப்ளை கட்டுப்பாட்டிற்கு இமிடாக்ளோப்ரிட் (0.5ml/L)',
    'Neem oil spray (5ml/L)': 'வேப்பெண்ணெய் தெளிப்பு (5ml/L)',
    'Remove and destroy infected plants':
        'பாதிக்கப்பட்ட செடிகளை அகற்றி அழிக்கவும்',
    'Control insect vectors (whitefly, aphids)':
        'பூச்சி பரப்பிகளை (வைட்ஃப்ளை, ஏபிட்) கட்டுப்படுத்தவும்',
    'Use reflective mulch': 'ஒளி பிரதிபலிக்கும் மழுப்புத் தாள் பயன்படுத்தவும்',
    'Plant resistant varieties next season':
        'அடுத்த பருவத்தில் நோய் எதிர்ப்பு வகைகளை நடவு செய்யவும்',
    'Sanitize equipment': 'உபகரணங்களை சுத்திகரிக்கவும்',
    'Viral diseases are spread by insects. Control vectors immediately to prevent spread.':
        'வைரஸ் நோய்கள் பூச்சிகளால் பரவும். பரவலைத் தடுக்க பரப்பி பூச்சிகளை உடனடியாக கட்டுப்படுத்தவும்.',
    'Reduce nitrogen': 'நைட்ரஜன் பயன்பாட்டை குறைக்கவும்',
    'Potassium sulfate (2g/L)': 'பொட்டாசியம் சல்பேட் (2g/L)',
    'Sulfur-based fungicide (3g/L)': 'சல்பர் அடிப்படையிலான பூஞ்சைநாசினி (3g/L)',
    'Azoxystrobin (1ml/L)': 'அசோக்ஸிஸ்ட்ரோபின் (1ml/L)',
    'Reduce humidity around plants':
        'செடிகளின் சுற்றுவட்ட ஈரப்பதத்தை குறைக்கவும்',
    'Apply sulfur fungicide every 10 days':
        'ஒவ்வொரு 10 நாள்களிலும் சல்பர் பூஞ்சைநாசினி பயன்படுத்தவும்',
    'Avoid overhead watering': 'மேலிருந்து நீர் ஊற்றுவதை தவிர்க்கவும்',
    'Remove heavily infected leaves': 'மிகவும் பாதிக்கப்பட்ட இலைகளை அகற்றவும்',
    'Mildew thrives in humid conditions. Improve air circulation and apply fungicide.':
        'ஈரப்பதம் அதிகமான சூழலில் மில்டியூ வேகமாக வளர்கிறது. காற்றோட்டத்தை மேம்படுத்தி பூஞ்சைநாசினி பயன்படுத்தவும்.',
    'Calcium supplement (2g/L)': 'கால்சியம் கூடுதல் (2g/L)',
    'Remove infected plant material': 'பாதிக்கப்பட்ட தாவரக் கழிவுகளை அகற்றவும்',
    'Apply fungicide at first sign':
        'முதல் அறிகுறியிலேயே பூஞ்சைநாசினி பயன்படுத்தவும்',
    'Maintain proper plant spacing': 'சரியான செடி இடைவெளியை பராமரிக்கவும்',
    'Avoid working with wet plants':
        'ஈரமான செடிகளில் வேலை செய்வதை தவிர்க்கவும்',
    'Fungal spots can rapidly spread. Early treatment with fungicide is key.':
        'பூஞ்சை புள்ளிகள் விரைவாக பரவலாம். ஆரம்பத்திலேயே பூஞ்சைநாசினி சிகிச்சை முக்கியம்.',
    'Reduce irrigation': 'நீர்ப்பாசனத்தை குறைக்கவும்',
    'Phosphorus-rich fertilizer (3g/L)': 'பாஸ்பரஸ் நிறைந்த உரம் (3g/L)',
    'Trichoderma-based biocontrol':
        'டிரைகோடெர்மா அடிப்படையிலான உயிர் கட்டுப்பாடு',
    'Improve soil drainage immediately': 'மண் வடிகாலை உடனடியாக மேம்படுத்தவும்',
    'Reduce watering frequency': 'நீர் ஊற்றும் அடிக்கடியை குறைக்கவும்',
    'Remove affected plants': 'பாதிக்கப்பட்ட செடிகளை அகற்றவும்',
    'Apply biocontrol agent to soil':
        'மண்ணில் உயிர் கட்டுப்பாட்டு பொருளை பயன்படுத்தவும்',
    'Do not replant in same spot': 'அதே இடத்தில் மீண்டும் நடவு செய்ய வேண்டாம்',
    'Root rot is caused by overwatering or poor drainage. Improve drainage immediately.':
        'அதிக நீர்ப்பாசனம் அல்லது மோசமான வடிகால் காரணமாக வேர் அழுகல் ஏற்படும். வடிகாலை உடனடியாக மேம்படுத்தவும்.',
    'Silicon supplement to strengthen plant':
        'செடியை வலுப்படுத்த சிலிகான் கூடுதல்',
    'Neem oil (10ml/L)': 'வேப்பெண்ணெய் (10ml/L)',
    'Identify and remove pests manually':
        'பூச்சிகளை கண்டறிந்து கையால் அகற்றவும்',
    'Apply insecticide in evening': 'மாலை நேரத்தில் பூச்சிக்கொல்லி தெளிக்கவும்',
    'Use pheromone traps': 'பெரோமோன் கண்ணிகள் பயன்படுத்தவும்',
    'Cover crops with nets': 'பயிர்களை வலைகளால் மூடவும்',
    'Repeat treatment after 7 days':
        '7 நாட்களுக்கு பிறகு சிகிச்சையை மீண்டும் செய்யவும்',
    'Insect pests cause physical damage. Early detection and targeted insecticide application is essential.':
        'பூச்சி தாக்குதல் தாவரத்திற்கு உடல் சேதம் ஏற்படுத்தும். ஆரம்பத்தில் கண்டறிந்து குறிவைத்து பூச்சிக்கொல்லி பயன்படுத்துவது அவசியம்.',
    'Balanced NPK fertilizer (2g/L)': 'சமநிலை NPK உரம் (2g/L)',
    'Micronutrient spray': 'நுண்ணூட்ட தெளிப்பு',
    'Broad-spectrum fungicide (2g/L)': 'பரந்த வரம்பு பூஞ்சைநாசினி (2g/L)',
    'Consult local agricultural extension officer':
        'உள்ளூர் வேளாண்மை விரிவாக்க அதிகாரியை அணுகவும்',
    'Remove visibly infected plant parts':
        'தெளிவாக பாதிக்கப்பட்ட செடி பகுதிகளை அகற்றவும்',
    'Apply recommended treatment':
        'பரிந்துரைக்கப்பட்ட சிகிச்சையை பயன்படுத்தவும்',
    'Monitor plant health weekly':
        'வாரந்தோறும் செடி ஆரோக்கியத்தை கண்காணிக்கவும்',
    'Take photos to track progress':
        'முன்னேற்றத்தை கண்காணிக்க புகைப்படங்களை எடுக்கவும்',
    'Disease detected. Apply the recommended treatment and monitor progress closely.':
        'நோய் கண்டறியப்பட்டுள்ளது. பரிந்துரைக்கப்பட்ட சிகிச்சையை செய்து முன்னேற்றத்தை நெருக்கமாக கண்காணிக்கவும்.',
  };

  static const Map<String, String> _knRecommendations = {
    'Continue regular NPK fertilization':
        'ಸಾಮಾನ್ಯ NPK ಗೊಬ್ಬರ ನೀಡುವಿಕೆಯನ್ನು ಮುಂದುವರಿಸಿ',
    'Maintain soil pH 6.0-7.0': 'ಮಣ್ಣಿನ pH 6.0-7.0 ನಡುವೆ ಇರಿಸಿ',
    'No pesticide needed': 'ಕೀಟನಾಶಕ ಅಗತ್ಯವಿಲ್ಲ',
    'Continue current care routine': 'ಪ್ರಸ್ತುತ ಸಂರಕ್ಷಣಾ ಕ್ರಮವನ್ನು ಮುಂದುವರಿಸಿ',
    'Monitor weekly': 'ವಾರಕ್ಕೊಮ್ಮೆ ನಿಗಾ ಇಡಿ',
    'Maintain proper watering': 'ಸರಿಯಾದ ನೀರಾವರಿಯನ್ನು ಕಾಪಾಡಿ',
    'Your crop appears healthy. Continue regular maintenance.':
        'ನಿಮ್ಮ ಬೆಳೆ ಆರೋಗ್ಯಕರವಾಗಿದೆ. ಸಾಮಾನ್ಯ ನಿರ್ವಹಣೆಯನ್ನು ಮುಂದುವರಿಸಿ.',
    'Calcium Nitrate spray (3g/L)': 'ಕ್ಯಾಲ್ಸಿಯಂ ನೈಟ್ರೇಟ್ ಸ್ಪ್ರೇ (3g/L)',
    'Remove and destroy infected leaves immediately':
        'ಸೋಂಕಿತ ಎಲೆಗಳನ್ನು ತಕ್ಷಣ ತೆಗೆದು ನಾಶಪಡಿಸಿ',
    'Apply fungicide every 7 days': 'ಪ್ರತಿ 7 ದಿನಕ್ಕೊಮ್ಮೆ ಫಂಗಿಸೈಡ್ ಬಳಸಿರಿ',
    'Avoid overhead irrigation': 'ಮೇಲಿನಿಂದ ನೀರಾವರಿ ತಪ್ಪಿಸಿ',
    'Improve air circulation': 'ಗಾಳಿಯ ಹರಿವು ಸುಧಾರಿಸಿ',
    'Monitor for 2 weeks': '2 ವಾರಗಳ ಕಾಲ ನಿಗಾ ಇಡಿ',
    'Blight is a fungal disease causing dark spots with concentric rings. Act quickly to prevent spread.':
        'ಬ್ಲೈಟ್ ಒಂದು ಹುಳು ರೋಗವಾಗಿದ್ದು ವಲಯಗಳಿರುವ ಕಪ್ಪು ಕಲೆಗಳನ್ನು ಉಂಟುಮಾಡುತ್ತದೆ. ಹರಡುವುದನ್ನು ತಡೆಯಲು ತಕ್ಷಣ ಕ್ರಮ ಕೈಗೊಳ್ಳಿ.',
    'Potassium-rich fertilizer (3g/L)': 'ಪೊಟ್ಯಾಸಿಯಂ ಸಮೃದ್ಧ ಗೊಬ್ಬರ (3g/L)',
    'Avoid excess nitrogen': 'ಅತಿಯಾದ ನೈಟ್ರೋಜನ್ ಬಳಕೆ ತಪ್ಪಿಸಿ',
    'Copper-based bactericide (3g/L)': 'ತಾಮ್ರ ಆಧಾರಿತ ಬ್ಯಾಕ್ಟೀರಿಯನಾಶಕ (3g/L)',
    'Streptomycin sulfate spray': 'ಸ್ಟ್ರೆಪ್ಟೊಮೈಸಿನ್ ಸಲ್ಫೇಟ್ ಸ್ಪ್ರೇ',
    'Remove infected plant parts': 'ಸೋಂಕಿತ ಸಸ್ಯ ಭಾಗಗಳನ್ನು ತೆಗೆದುಹಾಕಿ',
    'Disinfect tools after use':
        'ಬಳಕೆಯ ನಂತರ ಉಪಕರಣಗಳನ್ನು ಜಂತುನಾಶಕದಿಂದ ಶುದ್ಧಗೊಳಿಸಿ',
    'Apply copper bactericide weekly':
        'ವಾರಕ್ಕೊಮ್ಮೆ ತಾಮ್ರ ಆಧಾರಿತ ಬ್ಯಾಕ್ಟೀರಿಯನಾಶಕ ಬಳಸಿ',
    'Avoid wetting foliage': 'ಎಲೆಗಳು ತೇವವಾಗುವುದನ್ನು ತಪ್ಪಿಸಿ',
    'Isolate infected plants': 'ಸೋಂಕಿತ ಸಸ್ಯಗಳನ್ನು ಪ್ರತ್ಯೇಕಿಸಿ',
    'Bacterial disease spreads through water and wounds. Copper-based treatments are effective.':
        'ಬ್ಯಾಕ್ಟೀರಿಯಾ ರೋಗವು ನೀರು ಮತ್ತು ಗಾಯಗಳ ಮೂಲಕ ಹರಡುತ್ತದೆ. ತಾಮ್ರ ಆಧಾರಿತ ಚಿಕಿತ್ಸೆ ಪರಿಣಾಮಕಾರಿ.',
    'Balanced NPK': 'ಸಮತೋಲನ NPK',
    'Boron micronutrient (0.5g/L)': 'ಬೋರಾನ್ ಸೂಕ್ಷ್ಮ ಪೋಷಕಾಂಶ (0.5g/L)',
    'Imidacloprid (0.5ml/L) for whitefly control':
        'ವೈಟ್‌ಫ್ಲೈ ನಿಯಂತ್ರಣಕ್ಕೆ ಇಮಿಡಾಕ್ಲೋಪ್ರಿಡ್ (0.5ml/L)',
    'Neem oil spray (5ml/L)': 'ನೀಮ್ ಎಣ್ಣೆ ಸ್ಪ್ರೇ (5ml/L)',
    'Remove and destroy infected plants': 'ಸೋಂಕಿತ ಸಸ್ಯಗಳನ್ನು ತೆಗೆದು ನಾಶಪಡಿಸಿ',
    'Control insect vectors (whitefly, aphids)':
        'ಹರಡುವ ಕೀಟಗಳನ್ನು (ವೈಟ್‌ಫ್ಲೈ, ಆಫಿಡ್) ನಿಯಂತ್ರಿಸಿ',
    'Use reflective mulch': 'ಪ್ರತಿಫಲಿತ ಮಲ್ಚ್ ಬಳಸಿ',
    'Plant resistant varieties next season':
        'ಮುಂದಿನ ಹಂಗಾಮಿನಲ್ಲಿ ಪ್ರತಿರೋಧಕ ಜಾತಿಗಳನ್ನು ನೆಡಿ',
    'Sanitize equipment': 'ಉಪಕರಣಗಳನ್ನು ಸ್ವಚ್ಛಗೊಳಿಸಿ',
    'Viral diseases are spread by insects. Control vectors immediately to prevent spread.':
        'ವೈರಸ್ ರೋಗಗಳು ಕೀಟಗಳ ಮೂಲಕ ಹರಡುತ್ತವೆ. ಹರಡುವುದನ್ನು ತಡೆಯಲು ಹರಡುವ ಕೀಟಗಳನ್ನು ತಕ್ಷಣ ನಿಯಂತ್ರಿಸಿ.',
    'Reduce nitrogen': 'ನೈಟ್ರೋಜನ್ ಪ್ರಮಾಣ ಕಡಿಮೆ ಮಾಡಿ',
    'Potassium sulfate (2g/L)': 'ಪೊಟ್ಯಾಸಿಯಂ ಸಲ್ಫೇಟ್ (2g/L)',
    'Sulfur-based fungicide (3g/L)': 'ಗಂಧಕ ಆಧಾರಿತ ಫಂಗಿಸೈಡ್ (3g/L)',
    'Azoxystrobin (1ml/L)': 'ಅಜೋಕ್ಸಿಸ್ಟ್ರೋಬಿನ್ (1ml/L)',
    'Reduce humidity around plants': 'ಸಸ್ಯಗಳ ಸುತ್ತಲಿನ ತೇವಾಂಶವನ್ನು ಕಡಿಮೆ ಮಾಡಿ',
    'Apply sulfur fungicide every 10 days':
        'ಪ್ರತಿ 10 ದಿನಕ್ಕೊಮ್ಮೆ ಗಂಧಕ ಫಂಗಿಸೈಡ್ ಬಳಸಿ',
    'Avoid overhead watering': 'ಮೇಲಿನಿಂದ ನೀರು ಹಾಕುವುದನ್ನು ತಪ್ಪಿಸಿ',
    'Remove heavily infected leaves': 'ತೀವ್ರವಾಗಿ ಸೋಂಕಿತ ಎಲೆಗಳನ್ನು ತೆಗೆದುಹಾಕಿ',
    'Mildew thrives in humid conditions. Improve air circulation and apply fungicide.':
        'ಮಿಲ್ಡ್ಯೂ ತೇವಾಂಶ ಹೆಚ್ಚು ಇರುವ ಪರಿಸ್ಥಿತಿಯಲ್ಲಿ ವೇಗವಾಗಿ ಬೆಳೆಯುತ್ತದೆ. ಗಾಳಿಯ ಹರಿವು ಸುಧಾರಿಸಿ ಮತ್ತು ಫಂಗಿಸೈಡ್ ಬಳಸಿ.',
    'Calcium supplement (2g/L)': 'ಕ್ಯಾಲ್ಸಿಯಂ ಪೂರಕ (2g/L)',
    'Remove infected plant material': 'ಸೋಂಕಿತ ಸಸ್ಯ ಅವಶೇಷಗಳನ್ನು ತೆಗೆದುಹಾಕಿ',
    'Apply fungicide at first sign': 'ಮೊದಲ ಲಕ್ಷಣ ಕಂಡಾಗಲೇ ಫಂಗಿಸೈಡ್ ಬಳಸಿ',
    'Maintain proper plant spacing': 'ಸರಿಯಾದ ಸಸ್ಯ ಅಂತರವನ್ನು ಕಾಪಾಡಿ',
    'Avoid working with wet plants':
        'ತೇವ ಸಸ್ಯಗಳೊಂದಿಗೆ ಕೆಲಸ ಮಾಡುವುದನ್ನು ತಪ್ಪಿಸಿ',
    'Fungal spots can rapidly spread. Early treatment with fungicide is key.':
        'ಹುಳು ಕಲೆಗಳು ವೇಗವಾಗಿ ಹರಡಬಹುದು. ಆರಂಭಿಕ ಫಂಗಿಸೈಡ್ ಚಿಕಿತ್ಸೆ ಅತ್ಯಂತ ಮುಖ್ಯ.',
    'Reduce irrigation': 'ನೀರಾವರಿ ಪ್ರಮಾಣ ಕಡಿಮೆ ಮಾಡಿ',
    'Phosphorus-rich fertilizer (3g/L)': 'ಫಾಸ್ಫರಸ್ ಸಮೃದ್ಧ ಗೊಬ್ಬರ (3g/L)',
    'Trichoderma-based biocontrol': 'ಟ್ರೈಕೋಡರ್ಮಾ ಆಧಾರಿತ ಜೀವ ನಿಯಂತ್ರಣ',
    'Improve soil drainage immediately':
        'ಮಣ್ಣಿನ ನೀರು ಹರಿವು ವ್ಯವಸ್ಥೆಯನ್ನು ತಕ್ಷಣ ಸುಧಾರಿಸಿ',
    'Reduce watering frequency': 'ನೀರು ಹಾಕುವ ಅವಧಿಯನ್ನು ಕಡಿಮೆ ಮಾಡಿ',
    'Remove affected plants': 'ಬಾಧಿತ ಸಸ್ಯಗಳನ್ನು ತೆಗೆದುಹಾಕಿ',
    'Apply biocontrol agent to soil': 'ಮಣ್ಣಿಗೆ ಜೀವ ನಿಯಂತ್ರಣ ಏಜೆಂಟ್ ಬಳಸಿ',
    'Do not replant in same spot': 'ಅದೇ ಜಾಗದಲ್ಲಿ ಮರುನೆಡುವಿಕೆ ಮಾಡಬೇಡಿ',
    'Root rot is caused by overwatering or poor drainage. Improve drainage immediately.':
        'ಅತಿಯಾದ ನೀರಾವರಿ ಅಥವಾ ದುರ್ಬಲ ನೀರು ಹರಿವಿನಿಂದ ಬೇರು ಕುಲುಷ ಉಂಟಾಗುತ್ತದೆ. ನೀರು ಹರಿವನ್ನು ತಕ್ಷಣ ಸುಧಾರಿಸಿ.',
    'Silicon supplement to strengthen plant':
        'ಸಸ್ಯ ಬಲಪಡಿಸಲು ಸಿಲಿಕಾನ್ ಪೂರಕ ಬಳಸಿ',
    'Neem oil (10ml/L)': 'ನೀಮ್ ಎಣ್ಣೆ (10ml/L)',
    'Identify and remove pests manually':
        'ಕೀಟಗಳನ್ನು ಗುರುತಿಸಿ ಕೈಯಾರೆ ತೆಗೆದುಹಾಕಿ',
    'Apply insecticide in evening': 'ಸಂಜೆ ವೇಳೆಯಲ್ಲಿ ಕೀಟನಾಶಕ ಬಳಸಿ',
    'Use pheromone traps': 'ಫೆರೊಮೋನ್ ಟ್ರ್ಯಾಪ್‌ಗಳನ್ನು ಬಳಸಿ',
    'Cover crops with nets': 'ಬೆಳೆಗಳನ್ನು ಜಾಲಗಳಿಂದ ಮುಚ್ಚಿರಿ',
    'Repeat treatment after 7 days': '7 ದಿನಗಳ ನಂತರ ಚಿಕಿತ್ಸೆ ಪುನರಾವರ್ತಿಸಿ',
    'Insect pests cause physical damage. Early detection and targeted insecticide application is essential.':
        'ಕೀಟ ದಾಳಿ ಸಸ್ಯಕ್ಕೆ ಭೌತಿಕ ಹಾನಿ ಉಂಟುಮಾಡುತ್ತದೆ. ತ್ವರಿತ ಪತ್ತೆ ಮತ್ತು ಗುರಿತಪ್ಪದ ಕೀಟನಾಶಕ ಬಳಕೆ ಅತ್ಯಾವಶ್ಯಕ.',
    'Balanced NPK fertilizer (2g/L)': 'ಸಮತೋಲನ NPK ಗೊಬ್ಬರ (2g/L)',
    'Micronutrient spray': 'ಸೂಕ್ಷ್ಮ ಪೋಷಕಾಂಶ ಸ್ಪ್ರೇ',
    'Broad-spectrum fungicide (2g/L)': 'ವಿಸ್ತೃತ ವ್ಯಾಪ್ತಿ ಫಂಗಿಸೈಡ್ (2g/L)',
    'Consult local agricultural extension officer':
        'ಸ್ಥಳೀಯ ಕೃಷಿ ವಿಸ್ತರಣಾ ಅಧಿಕಾರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ',
    'Remove visibly infected plant parts':
        'ಸ್ಪಷ್ಟವಾಗಿ ಸೋಂಕಿತ ಸಸ್ಯ ಭಾಗಗಳನ್ನು ತೆಗೆದುಹಾಕಿ',
    'Apply recommended treatment': 'ಶಿಫಾರಸು ಮಾಡಿದ ಚಿಕಿತ್ಸೆ ಬಳಸಿ',
    'Monitor plant health weekly': 'ವಾರಕ್ಕೊಮ್ಮೆ ಸಸ್ಯ ಆರೋಗ್ಯವನ್ನು ಪರಿಶೀಲಿಸಿ',
    'Take photos to track progress': 'ಪ್ರಗತಿಯನ್ನು ಗಮನಿಸಲು ಫೋಟೋ ತೆಗೆದುಕೊಳ್ಳಿ',
    'Disease detected. Apply the recommended treatment and monitor progress closely.':
        'ರೋಗ ಪತ್ತೆಯಾಗಿದೆ. ಶಿಫಾರಸು ಮಾಡಿದ ಚಿಕಿತ್ಸೆಯನ್ನು ಬಳಸಿ ಮತ್ತು ಪ್ರಗತಿಯನ್ನು ಹತ್ತಿರವಾಗಿ ಗಮನಿಸಿ.',
  };

  static const Map<String, String> _recommendationAliases = {
    'NPK 20-20-20 (2g/L)': 'Balanced NPK fertilizer (2g/L)',
    'Mancozeb 75WP (2.5g/L)': 'Broad-spectrum fungicide (2g/L)',
    'Copper Oxychloride (3g/L)': 'Copper-based bactericide (3g/L)',
    'Blight is a fungal disease. Act quickly to prevent spread.':
        'Blight is a fungal disease causing dark spots with concentric rings. Act quickly to prevent spread.',
    'Bacterial disease spreads through water and wounds.':
        'Bacterial disease spreads through water and wounds. Copper-based treatments are effective.',
    'Imidacloprid (0.5ml/L) for whitefly':
        'Imidacloprid (0.5ml/L) for whitefly control',
    'Remove infected plants': 'Remove and destroy infected plants',
    'Control insect vectors': 'Control insect vectors (whitefly, aphids)',
    'Plant resistant varieties': 'Plant resistant varieties next season',
    'Viral diseases spread by insects. Control vectors immediately.':
        'Viral diseases are spread by insects. Control vectors immediately to prevent spread.',
    'Remove pests manually': 'Identify and remove pests manually',
    'Insect pests cause physical damage. Early detection is essential.':
        'Insect pests cause physical damage. Early detection and targeted insecticide application is essential.',
    'Disease detected. Apply the recommended treatment and monitor closely.':
        'Disease detected. Apply the recommended treatment and monitor progress closely.',
  };

  static const Map<String, String> _hiRecommendations = {
    'Continue regular NPK fertilization': 'नियमित NPK उर्वरक देना जारी रखें',
    'Maintain soil pH 6.0-7.0': 'मिट्टी का pH 6.0-7.0 के बीच बनाए रखें',
    'No pesticide needed': 'कीटनाशक की आवश्यकता नहीं है',
    'Continue current care routine': 'वर्तमान देखभाल जारी रखें',
    'Monitor weekly': 'हर सप्ताह निगरानी करें',
    'Maintain proper watering': 'उचित सिंचाई बनाए रखें',
    'Your crop appears healthy. Continue regular maintenance.':
        'आपकी फसल स्वस्थ दिख रही है। नियमित देखभाल जारी रखें।',
    'Balanced NPK fertilizer (2g/L)': 'संतुलित NPK उर्वरक (2g/L)',
    'Micronutrient spray': 'सूक्ष्म पोषक तत्व स्प्रे',
    'Broad-spectrum fungicide (2g/L)': 'ब्रॉड-स्पेक्ट्रम फफूंदनाशक (2g/L)',
    'Consult local agricultural extension officer':
        'स्थानीय कृषि विस्तार अधिकारी से सलाह लें',
    'Remove visibly infected plant parts':
        'स्पष्ट रूप से संक्रमित पौधे के हिस्से हटाएं',
    'Apply recommended treatment': 'सिफारिश किया गया उपचार लागू करें',
    'Monitor plant health weekly':
        'पौधों के स्वास्थ्य की साप्ताहिक निगरानी करें',
    'Take photos to track progress': 'प्रगति देखने के लिए फोटो लें',
    'Calcium Nitrate spray (3g/L)': 'कैल्शियम नाइट्रेट स्प्रे (3g/L)',
    'Remove and destroy infected leaves immediately':
        'संक्रमित पत्तियों को तुरंत हटाकर नष्ट करें',
    'Apply fungicide every 7 days': 'हर 7 दिन में फफूंदनाशक लगाएं',
    'Avoid overhead irrigation': 'ऊपर से सिंचाई करने से बचें',
    'Improve air circulation': 'हवा का प्रवाह बेहतर करें',
    'Monitor for 2 weeks': '2 सप्ताह तक निगरानी करें',
    'Blight is a fungal disease causing dark spots with concentric rings. Act quickly to prevent spread.':
        'ब्लाइट एक फफूंद रोग है जो काले धब्बे बनाता है। फैलाव रोकने के लिए तुरंत कार्य करें।',
    'Potassium-rich fertilizer (3g/L)': 'पोटैशियम युक्त उर्वरक (3g/L)',
    'Avoid excess nitrogen': 'अधिक नाइट्रोजन से बचें',
    'Copper-based bactericide (3g/L)': 'तांबा आधारित जीवाणुनाशक (3g/L)',
    'Streptomycin sulfate spray': 'स्ट्रेप्टोमाइसिन सल्फेट स्प्रे',
    'Remove infected plant parts': 'संक्रमित पौधों के हिस्से हटाएं',
    'Disinfect tools after use': 'उपयोग के बाद उपकरणों को कीटाणुरहित करें',
    'Apply copper bactericide weekly':
        'हर सप्ताह तांबा आधारित जीवाणुनाशक लगाएं',
    'Avoid wetting foliage': 'पत्तियों को अधिक गीला न करें',
    'Isolate infected plants': 'संक्रमित पौधों को अलग रखें',
    'Bacterial disease spreads through water and wounds. Copper-based treatments are effective.':
        'जीवाणु रोग पानी और घावों से फैलता है। तांबा आधारित उपचार प्रभावी हैं।',
    'Balanced NPK': 'संतुलित NPK',
    'Boron micronutrient (0.5g/L)': 'बोरॉन सूक्ष्म पोषक तत्व (0.5g/L)',
    'Imidacloprid (0.5ml/L) for whitefly control':
        'सफेद मक्खी नियंत्रण के लिए इमिडाक्लोप्रिड (0.5ml/L)',
    'Neem oil spray (5ml/L)': 'नीम तेल स्प्रे (5ml/L)',
    'Remove and destroy infected plants': 'संक्रमित पौधों को हटाकर नष्ट करें',
    'Control insect vectors (whitefly, aphids)':
        'कीट वाहकों (सफेद मक्खी, एफिड) को नियंत्रित करें',
    'Use reflective mulch': 'प्रतिबिंबित मल्च का उपयोग करें',
    'Plant resistant varieties next season':
        'अगले मौसम में रोग-प्रतिरोधी किस्में लगाएं',
    'Sanitize equipment': 'उपकरणों को स्वच्छ रखें',
    'Viral diseases are spread by insects. Control vectors immediately to prevent spread.':
        'वायरल रोग कीटों से फैलते हैं। फैलाव रोकने के लिए वाहकों को तुरंत नियंत्रित करें।',
    'Reduce nitrogen': 'नाइट्रोजन कम करें',
    'Potassium sulfate (2g/L)': 'पोटैशियम सल्फेट (2g/L)',
    'Sulfur-based fungicide (3g/L)': 'सल्फर आधारित फफूंदनाशक (3g/L)',
    'Azoxystrobin (1ml/L)': 'एज़ॉक्सीस्ट्रोबिन (1ml/L)',
    'Reduce humidity around plants': 'पौधों के आसपास की नमी कम करें',
    'Apply sulfur fungicide every 10 days':
        'हर 10 दिन में सल्फर फफूंदनाशक लगाएं',
    'Avoid overhead watering': 'ऊपर से पानी देने से बचें',
    'Remove heavily infected leaves': 'बहुत अधिक संक्रमित पत्तियों को हटाएं',
    'Mildew thrives in humid conditions. Improve air circulation and apply fungicide.':
        'मिल्ड्यू नमी में तेजी से बढ़ता है। हवा का प्रवाह बढ़ाएं और फफूंदनाशक लगाएं।',
    'Calcium supplement (2g/L)': 'कैल्शियम सप्लीमेंट (2g/L)',
    'Remove infected plant material': 'संक्रमित पौध अवशेष हटाएं',
    'Apply fungicide at first sign': 'पहले लक्षण पर ही फफूंदनाशक लगाएं',
    'Maintain proper plant spacing': 'पौधों के बीच उचित दूरी रखें',
    'Avoid working with wet plants': 'गीले पौधों पर काम करने से बचें',
    'Fungal spots can rapidly spread. Early treatment with fungicide is key.':
        'फफूंदी के धब्बे तेजी से फैल सकते हैं। शुरुआती फफूंदनाशक उपचार महत्वपूर्ण है।',
    'Reduce irrigation': 'सिंचाई कम करें',
    'Phosphorus-rich fertilizer (3g/L)': 'फॉस्फोरस युक्त उर्वरक (3g/L)',
    'Trichoderma-based biocontrol': 'ट्राइकोडर्मा आधारित जैव नियंत्रण',
    'Improve soil drainage immediately': 'मिट्टी की जलनिकासी तुरंत सुधारें',
    'Reduce watering frequency': 'पानी देने की आवृत्ति कम करें',
    'Remove affected plants': 'प्रभावित पौधों को हटाएं',
    'Apply biocontrol agent to soil': 'मिट्टी में जैव नियंत्रण एजेंट डालें',
    'Do not replant in same spot': 'उसी स्थान पर दोबारा रोपण न करें',
    'Root rot is caused by overwatering or poor drainage. Improve drainage immediately.':
        'जड़ सड़न अधिक पानी या खराब जलनिकासी से होती है। जलनिकासी तुरंत सुधारें।',
    'Silicon supplement to strengthen plant':
        'पौधे को मजबूत करने के लिए सिलिकॉन सप्लीमेंट दें',
    'Spinosad (1ml/L)': 'स्पिनोसैड (1ml/L)',
    'Neem oil (10ml/L)': 'नीम तेल (10ml/L)',
    'Chlorpyrifos (2ml/L)': 'क्लोरपाइरीफॉस (2ml/L)',
    'Identify and remove pests manually':
        'कीटों की पहचान कर उन्हें हाथ से हटाएं',
    'Apply insecticide in evening': 'शाम के समय कीटनाशक लगाएं',
    'Use pheromone traps': 'फेरोमोन ट्रैप का उपयोग करें',
    'Cover crops with nets': 'फसलों को जाल से ढकें',
    'Repeat treatment after 7 days': '7 दिनों बाद उपचार दोहराएं',
    'Insect pests cause physical damage. Early detection and targeted insecticide application is essential.':
        'कीट शारीरिक नुकसान पहुंचाते हैं। जल्दी पहचान और सही कीटनाशक उपयोग आवश्यक है।',
    'Disease detected. Apply the recommended treatment and monitor progress closely.':
        'रोग पाया गया है। सुझाया गया उपचार करें और प्रगति की ध्यान से निगरानी करें।',
  };

  static const Map<String, String> _teRecommendations = {
    'Continue regular NPK fertilization': 'సాధారణ NPK ఎరువును కొనసాగించండి',
    'Maintain soil pH 6.0-7.0': 'మట్టి pH 6.0-7.0 మధ్య ఉంచండి',
    'No pesticide needed': 'పురుగుమందు అవసరం లేదు',
    'Continue current care routine': 'ప్రస్తుత సంరక్షణను కొనసాగించండి',
    'Monitor weekly': 'ప్రతి వారం పర్యవేక్షించండి',
    'Maintain proper watering': 'సరైన నీరుపోసే విధానాన్ని కొనసాగించండి',
    'Your crop appears healthy. Continue regular maintenance.':
        'మీ పంట ఆరోగ్యంగా కనిపిస్తోంది. సాధారణ సంరక్షణను కొనసాగించండి.',
    'Balanced NPK fertilizer (2g/L)': 'సమతుల్య NPK ఎరువు (2g/L)',
    'Micronutrient spray': 'సూక్ష్మ పోషక స్ప్రే',
    'Broad-spectrum fungicide (2g/L)': 'విస్తృత శ్రేణి ఫంగిసైడ్ (2g/L)',
    'Consult local agricultural extension officer':
        'స్థానిక వ్యవసాయ విస్తరణ అధికారిని సంప్రదించండి',
    'Remove visibly infected plant parts':
        'స్పష్టంగా సోకిన మొక్క భాగాలను తొలగించండి',
    'Apply recommended treatment': 'సిఫారసు చేసిన చికిత్సను అమలు చేయండి',
    'Monitor plant health weekly': 'మొక్క ఆరోగ్యాన్ని ప్రతి వారం తనిఖీ చేయండి',
    'Take photos to track progress': 'పురోగతిని గమనించడానికి ఫోటోలు తీయండి',
    'Calcium Nitrate spray (3g/L)': 'కాల్షియం నైట్రేట్ స్ప్రే (3g/L)',
    'Remove and destroy infected leaves immediately':
        'సోకిన ఆకులను వెంటనే తొలగించి నాశనం చేయండి',
    'Apply fungicide every 7 days': 'ప్రతి 7 రోజులకు ఫంగిసైడ్ ఉపయోగించండి',
    'Avoid overhead irrigation': 'పై నుండి నీరుపోసే విధానాన్ని నివారించండి',
    'Improve air circulation': 'గాలి ప్రసరణను మెరుగుపరచండి',
    'Monitor for 2 weeks': '2 వారాలు పర్యవేక్షించండి',
    'Blight is a fungal disease causing dark spots with concentric rings. Act quickly to prevent spread.':
        'బ్లైట్ ఒక ఫంగల్ వ్యాధి. వ్యాప్తి చెందకముందే త్వరగా చర్య తీసుకోండి.',
    'Potassium-rich fertilizer (3g/L)': 'పొటాషియం అధికంగా ఉన్న ఎరువు (3g/L)',
    'Avoid excess nitrogen': 'అధిక నైట్రోజన్‌ను నివారించండి',
    'Copper-based bactericide (3g/L)': 'తామ్ర ఆధారిత బ్యాక్టీరియనాశిని (3g/L)',
    'Streptomycin sulfate spray': 'స్ట్రెప్టోమైసిన్ సల్ఫేట్ స్ప్రే',
    'Remove infected plant parts': 'సోకిన మొక్క భాగాలను తొలగించండి',
    'Disinfect tools after use': 'ఉపయోగం తర్వాత పరికరాలను శుభ్రపరచండి',
    'Apply copper bactericide weekly':
        'ప్రతి వారం తామ్ర బ్యాక్టీరియనాశిని ఉపయోగించండి',
    'Avoid wetting foliage': 'ఆకులు ఎక్కువగా తడవకుండా చూడండి',
    'Isolate infected plants': 'సోకిన మొక్కలను వేరుచేయండి',
    'Bacterial disease spreads through water and wounds. Copper-based treatments are effective.':
        'బ్యాక్టీరియా వ్యాధి నీరు మరియు గాయాల ద్వారా వ్యాపిస్తుంది. తామ్ర ఆధారిత చికిత్స ప్రభావవంతం.',
    'Balanced NPK': 'సమతుల్య NPK',
    'Boron micronutrient (0.5g/L)': 'బోరాన్ సూక్ష్మ పోషకం (0.5g/L)',
    'Imidacloprid (0.5ml/L) for whitefly control':
        'తెల్ల ఈగ నియంత్రణకు ఇమిడాక్లోప్రిడ్ (0.5ml/L)',
    'Neem oil spray (5ml/L)': 'వేప నూనె స్ప్రే (5ml/L)',
    'Remove and destroy infected plants':
        'సోకిన మొక్కలను తొలగించి నాశనం చేయండి',
    'Control insect vectors (whitefly, aphids)':
        'పురుగుల వాహకాలను (తెల్ల ఈగ, ఆఫిడ్) నియంత్రించండి',
    'Use reflective mulch': 'ప్రతిబింబించే మల్చ్ ఉపయోగించండి',
    'Plant resistant varieties next season':
        'తదుపరి సీజన్‌లో నిరోధక రకాలను నాటండి',
    'Sanitize equipment': 'పరికరాలను శుభ్రంగా ఉంచండి',
    'Viral diseases are spread by insects. Control vectors immediately to prevent spread.':
        'వైరల్ వ్యాధులు పురుగుల ద్వారా వ్యాపిస్తాయి. వ్యాప్తి నివారించడానికి వాటిని వెంటనే నియంత్రించండి.',
    'Reduce nitrogen': 'నైట్రోజన్ పరిమాణాన్ని తగ్గించండి',
    'Potassium sulfate (2g/L)': 'పొటాషియం సల్ఫేట్ (2g/L)',
    'Sulfur-based fungicide (3g/L)': 'సల్ఫర్ ఆధారిత ఫంగిసైడ్ (3g/L)',
    'Azoxystrobin (1ml/L)': 'అజోక్సిస్ట్రోబిన్ (1ml/L)',
    'Reduce humidity around plants': 'మొక్కల చుట్టూ తేమను తగ్గించండి',
    'Apply sulfur fungicide every 10 days':
        'ప్రతి 10 రోజులకు సల్ఫర్ ఫంగిసైడ్ వాడండి',
    'Avoid overhead watering': 'పై నుంచి నీరు పోయడం నివారించండి',
    'Remove heavily infected leaves': 'తీవ్రంగా సోకిన ఆకులను తొలగించండి',
    'Mildew thrives in humid conditions. Improve air circulation and apply fungicide.':
        'తేమ ఉన్న వాతావరణంలో మిల్డ్యూ వేగంగా పెరుగుతుంది. గాలి ప్రసరణను మెరుగుపరచి ఫంగిసైడ్ వాడండి.',
    'Calcium supplement (2g/L)': 'కాల్షియం సప్లిమెంట్ (2g/L)',
    'Remove infected plant material': 'సోకిన మొక్క అవశేషాలను తొలగించండి',
    'Apply fungicide at first sign': 'మొదటి లక్షణం కనిపించగానే ఫంగిసైడ్ వాడండి',
    'Maintain proper plant spacing': 'మొక్కల మధ్య సరైన దూరం ఉంచండి',
    'Avoid working with wet plants': 'తడి మొక్కలపై పని చేయకుండా ఉండండి',
    'Fungal spots can rapidly spread. Early treatment with fungicide is key.':
        'ఫంగల్ మచ్చలు వేగంగా వ్యాపిస్తాయి. ప్రారంభ దశలో ఫంగిసైడ్ చికిత్స ముఖ్యం.',
    'Reduce irrigation': 'నీటిపారుదల తగ్గించండి',
    'Phosphorus-rich fertilizer (3g/L)': 'ఫాస్ఫరస్ అధికంగా ఉన్న ఎరువు (3g/L)',
    'Trichoderma-based biocontrol': 'ట్రైకోడెర్మా ఆధారిత జీవ నియంత్రణ',
    'Improve soil drainage immediately': 'మట్టి డ్రైనేజీని వెంటనే మెరుగుపరచండి',
    'Reduce watering frequency': 'నీరు పెట్టే తరచుదనాన్ని తగ్గించండి',
    'Remove affected plants': 'ప్రభావిత మొక్కలను తొలగించండి',
    'Apply biocontrol agent to soil':
        'మట్టిలో జీవ నియంత్రణ ద్రావణం ఉపయోగించండి',
    'Do not replant in same spot': 'అదే చోట మళ్లీ నాటవద్దు',
    'Root rot is caused by overwatering or poor drainage. Improve drainage immediately.':
        'అధిక నీరు లేదా బలహీన డ్రైనేజీ వల్ల వేరు కుళ్లు వస్తుంది. డ్రైనేజీని వెంటనే మెరుగుపరచండి.',
    'Silicon supplement to strengthen plant':
        'మొక్క బలపడేందుకు సిలికాన్ సప్లిమెంట్ ఇవ్వండి',
    'Spinosad (1ml/L)': 'స్పినోసాడ్ (1ml/L)',
    'Neem oil (10ml/L)': 'వేప నూనె (10ml/L)',
    'Chlorpyrifos (2ml/L)': 'క్లోర్‌పైరిఫాస్ (2ml/L)',
    'Identify and remove pests manually':
        'పురుగులను గుర్తించి చేతితో తొలగించండి',
    'Apply insecticide in evening': 'సాయంత్రం పురుగుమందు ఉపయోగించండి',
    'Use pheromone traps': 'ఫెరోమోన్ ట్రాప్‌లను ఉపయోగించండి',
    'Cover crops with nets': 'పంటలను వలలతో కప్పండి',
    'Repeat treatment after 7 days': '7 రోజుల తర్వాత చికిత్సను మళ్లీ చేయండి',
    'Insect pests cause physical damage. Early detection and targeted insecticide application is essential.':
        'పురుగులు భౌతిక నష్టం కలిగిస్తాయి. ముందస్తుగా గుర్తించి సరైన పురుగుమందు ఉపయోగించడం ముఖ్యం.',
    'Disease detected. Apply the recommended treatment and monitor progress closely.':
        'వ్యాధి గుర్తించబడింది. సిఫారసు చేసిన చికిత్సను ఉపయోగించి పురోగతిని జాగ్రత్తగా పర్యవేక్షించండి.',
  };

  static const Map<String, String> _mlRecommendations = {
    'Continue regular NPK fertilization': 'സാധാരണ NPK വളം നൽകുന്നത് തുടരുക',
    'Maintain soil pH 6.0-7.0': 'മണ്ണിന്റെ pH 6.0-7.0 നിലനിർത്തുക',
    'No pesticide needed': 'കീടനാശിനി ആവശ്യമില്ല',
    'Continue current care routine': 'നിലവിലെ പരിപാലനം തുടരുക',
    'Monitor weekly': 'ഓരോ ആഴ്ചയും നിരീക്ഷിക്കുക',
    'Maintain proper watering': 'ശരിയായ ജലസേചനം നിലനിർത്തുക',
    'Your crop appears healthy. Continue regular maintenance.':
        'നിങ്ങളുടെ വിള ആരോഗ്യമുള്ളതായി തോന്നുന്നു. സാധാരണ പരിപാലനം തുടരുക.',
    'Balanced NPK fertilizer (2g/L)': 'സമതുലിത NPK വളം (2g/L)',
    'Micronutrient spray': 'സൂക്ഷ്മ പോഷക സ്പ്രേ',
    'Broad-spectrum fungicide (2g/L)': 'വ്യാപക ശ്രേണി ഫംഗിസൈഡ് (2g/L)',
    'Consult local agricultural extension officer':
        'പ്രാദേശിക കാർഷിക ഉദ്യോഗസ്ഥനോട് ആശയവിനിമയം നടത്തുക',
    'Remove visibly infected plant parts':
        'വ്യക്തമായി ബാധിച്ച സസ്യഭാഗങ്ങൾ നീക്കുക',
    'Apply recommended treatment': 'ശുപാർശ ചെയ്ത ചികിത്സ പ്രയോഗിക്കുക',
    'Monitor plant health weekly':
        'ചെടികളുടെ ആരോഗ്യത്തെ ആഴ്ചതോറും പരിശോധിക്കുക',
    'Take photos to track progress': 'പുരോഗതി നോക്കാൻ ചിത്രങ്ങൾ എടുക്കുക',
    'Calcium Nitrate spray (3g/L)': 'കാൽസ്യം നൈട്രേറ്റ് സ്പ്രേ (3g/L)',
    'Remove and destroy infected leaves immediately':
        'ബാധിച്ച ഇലകൾ ഉടൻ നീക്കി നശിപ്പിക്കുക',
    'Apply fungicide every 7 days': 'ഓരോ 7 ദിവസവും ഫംഗിസൈഡ് പ്രയോഗിക്കുക',
    'Avoid overhead irrigation': 'മുകളിൽ നിന്ന് ജലസേചനം ഒഴിവാക്കുക',
    'Improve air circulation': 'വായു സഞ്ചാരം മെച്ചപ്പെടുത്തുക',
    'Monitor for 2 weeks': '2 ആഴ്ച നിരീക്ഷിക്കുക',
    'Blight is a fungal disease causing dark spots with concentric rings. Act quickly to prevent spread.':
        'ബ്ലൈറ്റ് ഒരു ഫംഗസ് രോഗമാണ്. പടരുന്നതിന് മുമ്പ് വേഗത്തിൽ നടപടി സ്വീകരിക്കുക.',
    'Potassium-rich fertilizer (3g/L)': 'പൊട്ടാസ്യം സമൃദ്ധമായ വളം (3g/L)',
    'Avoid excess nitrogen': 'അമിതമായ നൈട്രജൻ ഒഴിവാക്കുക',
    'Copper-based bactericide (3g/L)': 'താമ്ര അധിഷ്ഠിത ബാക്ടീരിയനാശിനി (3g/L)',
    'Streptomycin sulfate spray': 'സ്ട്രെപ്റ്റോമൈസിൻ സൾഫേറ്റ് സ്പ്രേ',
    'Remove infected plant parts': 'ബാധിച്ച സസ്യഭാഗങ്ങൾ നീക്കുക',
    'Disinfect tools after use':
        'ഉപയോഗത്തിന് ശേഷം ഉപകരണങ്ങൾ അണുനശീകരണം ചെയ്യുക',
    'Apply copper bactericide weekly':
        'ഓരോ ആഴ്ചയും താമ്ര ബാക്ടീരിയനാശിനി പ്രയോഗിക്കുക',
    'Avoid wetting foliage': 'ഇലകൾ അമിതമായി നനയുന്നത് ഒഴിവാക്കുക',
    'Isolate infected plants': 'ബാധിച്ച ചെടികളെ വേർതിരിച്ച് സൂക്ഷിക്കുക',
    'Bacterial disease spreads through water and wounds. Copper-based treatments are effective.':
        'ബാക്ടീരിയ രോഗം വെള്ളത്തിലൂടെയും മുറിവുകളിലൂടെയും പടരുന്നു. താമ്ര ചികിത്സ ഫലപ്രദമാണ്.',
    'Balanced NPK': 'സമതുലിത NPK',
    'Boron micronutrient (0.5g/L)': 'ബോറോൺ സൂക്ഷ്മപോഷകം (0.5g/L)',
    'Imidacloprid (0.5ml/L) for whitefly control':
        'വൈറ്റ്‌ഫ്ലൈ നിയന്ത്രണത്തിന് ഇമിഡാക്ലോപ്രിഡ് (0.5ml/L)',
    'Neem oil spray (5ml/L)': 'വേപ്പെണ്ണ സ്പ്രേ (5ml/L)',
    'Remove and destroy infected plants': 'ബാധിച്ച ചെടികൾ നീക്കി നശിപ്പിക്കുക',
    'Control insect vectors (whitefly, aphids)':
        'കീട വഹകരെ (വൈറ്റ്‌ഫ്ലൈ, ആഫിഡ്) നിയന്ത്രിക്കുക',
    'Use reflective mulch': 'പ്രതിഫലിക്കുന്ന മൾച്ച് ഉപയോഗിക്കുക',
    'Plant resistant varieties next season':
        'അടുത്ത സീസണിൽ പ്രതിരോധ ശേഷിയുള്ള ഇനങ്ങൾ നട്ട് വളർത്തുക',
    'Sanitize equipment': 'ഉപകരണങ്ങൾ ശുചിയായി സൂക്ഷിക്കുക',
    'Viral diseases are spread by insects. Control vectors immediately to prevent spread.':
        'വൈറസ് രോഗങ്ങൾ കീടങ്ങളിലൂടെ പടരുന്നു. പടരുന്നത് തടയാൻ വഹകരെ ഉടൻ നിയന്ത്രിക്കുക.',
    'Reduce nitrogen': 'നൈട്രജൻ കുറയ്ക്കുക',
    'Potassium sulfate (2g/L)': 'പൊട്ടാസ്യം സൾഫേറ്റ് (2g/L)',
    'Sulfur-based fungicide (3g/L)': 'സൾഫർ അധിഷ്ഠിത ഫംഗിസൈഡ് (3g/L)',
    'Azoxystrobin (1ml/L)': 'അസോക്സിസ്ട്രോബിൻ (1ml/L)',
    'Reduce humidity around plants': 'ചെടികളുടെ ചുറ്റുമുള്ള ഈർപ്പം കുറയ്ക്കുക',
    'Apply sulfur fungicide every 10 days':
        'ഓരോ 10 ദിവസത്തിലും സൾഫർ ഫംഗിസൈഡ് പ്രയോഗിക്കുക',
    'Avoid overhead watering': 'മുകളിൽ നിന്ന് വെള്ളമൊഴിക്കുന്നത് ഒഴിവാക്കുക',
    'Remove heavily infected leaves': 'ഗുരുതരമായി ബാധിച്ച ഇലകൾ നീക്കുക',
    'Mildew thrives in humid conditions. Improve air circulation and apply fungicide.':
        'ഈർപ്പം കൂടിയ സാഹചര്യത്തിൽ മിൽഡ്യൂ വേഗത്തിൽ വളരും. വായുസഞ്ചാരം മെച്ചപ്പെടുത്തി ഫംഗിസൈഡ് പ്രയോഗിക്കുക.',
    'Calcium supplement (2g/L)': 'കാൽസ്യം സപ്ലിമെന്റ് (2g/L)',
    'Remove infected plant material': 'ബാധിച്ച സസ്യാവശിഷ്ടങ്ങൾ നീക്കുക',
    'Apply fungicide at first sign':
        'ആദ്യ ലക്ഷണത്തിൽ തന്നെ ഫംഗിസൈഡ് പ്രയോഗിക്കുക',
    'Maintain proper plant spacing': 'ചെടികൾക്ക് ശരിയായ ഇടവിട്ട് നിലനിർത്തുക',
    'Avoid working with wet plants':
        'നനഞ്ഞ ചെടികളിൽ ജോലി ചെയ്യുന്നത് ഒഴിവാക്കുക',
    'Fungal spots can rapidly spread. Early treatment with fungicide is key.':
        'ഫംഗസ് പാടുകൾ വേഗത്തിൽ പടരും. തുടക്കത്തിൽ ഫംഗിസൈഡ് ചികിത്സ നിർണായകമാണ്.',
    'Reduce irrigation': 'ജലസേചനം കുറയ്ക്കുക',
    'Phosphorus-rich fertilizer (3g/L)': 'ഫോസ്ഫറസ് സമൃദ്ധമായ വളം (3g/L)',
    'Trichoderma-based biocontrol': 'ട്രൈക്കോഡർമ അധിഷ്ഠിത ജീവ നിയന്ത്രണം',
    'Improve soil drainage immediately':
        'മണ്ണിന്റെ ഡ്രെയിനേജ് ഉടൻ മെച്ചപ്പെടുത്തുക',
    'Reduce watering frequency': 'വെള്ളമൊഴിക്കുന്ന ആവൃത്തി കുറയ്ക്കുക',
    'Remove affected plants': 'ബാധിച്ച ചെടികൾ നീക്കുക',
    'Apply biocontrol agent to soil':
        'മണ്ണിൽ ജീവ നിയന്ത്രണ ഏജന്റ് പ്രയോഗിക്കുക',
    'Do not replant in same spot': 'അതേ സ്ഥലത്ത് വീണ്ടും നട്ട് വളർത്തരുത്',
    'Root rot is caused by overwatering or poor drainage. Improve drainage immediately.':
        'അമിതമായ വെള്ളമോ മോശം ഡ്രെയിനേജിയോ കാരണം വേർ ചെരിച്ചിൽ ഉണ്ടാകും. ഡ്രെയിനേജ് ഉടൻ മെച്ചപ്പെടുത്തുക.',
    'Silicon supplement to strengthen plant':
        'ചെടി ശക്തമാക്കാൻ സിലിക്കൺ സപ്ലിമെന്റ് നൽകുക',
    'Spinosad (1ml/L)': 'സ്പിനോസാഡ് (1ml/L)',
    'Neem oil (10ml/L)': 'വേപ്പെണ്ണ (10ml/L)',
    'Chlorpyrifos (2ml/L)': 'ക്ലോർപൈരിഫോസ് (2ml/L)',
    'Identify and remove pests manually': 'കീടങ്ങളെ കണ്ടെത്തി കൈകൊണ്ട് നീക്കുക',
    'Apply insecticide in evening': 'വൈകുന്നേരം കീടനാശിനി പ്രയോഗിക്കുക',
    'Use pheromone traps': 'ഫെറോമോൺ ട്രാപ്പുകൾ ഉപയോഗിക്കുക',
    'Cover crops with nets': 'വിളകൾ വല കൊണ്ട് മൂടുക',
    'Repeat treatment after 7 days': '7 ദിവസത്തിന് ശേഷം ചികിത്സ ആവർത്തിക്കുക',
    'Insect pests cause physical damage. Early detection and targeted insecticide application is essential.':
        'കീടങ്ങൾ ഭൗതിക നാശം വരുത്തുന്നു. നേരത്തെ കണ്ടെത്തലും ശരിയായ കീടനാശിനി പ്രയോഗവും പ്രധാനമാണ്.',
    'Disease detected. Apply the recommended treatment and monitor progress closely.':
        'രോഗം കണ്ടെത്തി. ശുപാർശ ചെയ്ത ചികിത്സ പ്രയോഗിച്ച് പുരോഗതി ശ്രദ്ധാപൂർവ്വം നിരീക്ഷിക്കുക.',
  };
}
