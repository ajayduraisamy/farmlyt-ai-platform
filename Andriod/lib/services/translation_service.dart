import 'package:dio/dio.dart';
import '../utils/app_constants.dart';

class TranslationService {
  TranslationService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {'Accept': 'application/json'},
    ),
  );

  static const String _googleTranslateUrl =
      'https://translation.googleapis.com/language/translate/v2';

  static const String _proxyUrl = String.fromEnvironment(
    'TRANSLATION_PROXY_URL',
    defaultValue: '',
  );

  // ── FIX: hardcode the key directly since you're not using --dart-define ──
  static const String _apiKey = 'AIzaSyABKbr1YhAvLckQBw7PaLfVEbEFCBnzTz4';

  static const int _maxCacheSize = 500;
  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _inFlight = {};
  static final Map<String, Future<List<String>>> _batchInFlight = {};

  static Future<String> translateCached({
    required String text,
    required String targetLang,
    String sourceLang = 'en',
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty || targetLang == 'en') return text;

    final key = '$sourceLang::$targetLang::$normalizedText';
    final cached = _cache[key];
    if (cached != null) return cached;

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final task = translate(
      text: normalizedText,
      targetLang: targetLang,
      sourceLang: sourceLang,
    ).then((value) {
      _evictIfNeeded();
      _cache[key] = value;
      _inFlight.remove(key);
      return value;
    }).catchError((_) {
      _inFlight.remove(key);
      return text;
    });

    _inFlight[key] = task;
    return task;
  }

  static Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'en',
  }) async {
    if (text.trim().isEmpty || targetLang == 'en') return text;

    try {
      if (_proxyUrl.trim().isNotEmpty) {
        final viaProxy = await _translateViaProxy(
          text: text,
          targetLang: targetLang,
          sourceLang: sourceLang,
        );
        if (viaProxy.trim().isNotEmpty) return viaProxy;
      }

      final viaGoogle = await _translateViaGoogle(
        text: text,
        targetLang: targetLang,
        sourceLang: sourceLang,
      );
      if (viaGoogle.trim().isNotEmpty) return viaGoogle;
    } on DioException {
      // Network failure — fall through
    } catch (_) {
      // Any other error — fall through
    }

    return text;
  }

  static Future<List<String>> translateBatchCached({
    required List<String> texts,
    required String targetLang,
    String sourceLang = 'en',
  }) async {
    if (texts.isEmpty || targetLang == 'en') return texts;

    final normalized = texts.map((t) => t.trim()).toList(growable: false);
    final results = List<String>.filled(normalized.length, '');
    final uncachedIndices = <int>[];
    final uncachedTexts = <String>[];

    for (var i = 0; i < normalized.length; i++) {
      final key = '$sourceLang::$targetLang::${normalized[i]}';
      final cached = _cache[key];
      if (cached != null) {
        results[i] = cached;
      } else {
        uncachedIndices.add(i);
        uncachedTexts.add(normalized[i]);
      }
    }

    if (uncachedTexts.isEmpty) return results;

    final batchKey = '$sourceLang::$targetLang::${uncachedTexts.join('||')}';
    final existingTask = _batchInFlight[batchKey];

    final task = existingTask ??
        _translateBatch(
          texts: uncachedTexts,
          targetLang: targetLang,
          sourceLang: sourceLang,
        ).then((translated) {
          _batchInFlight.remove(batchKey);
          return translated;
        }).catchError((_) {
          _batchInFlight.remove(batchKey);
          return uncachedTexts;
        });

    if (existingTask == null) _batchInFlight[batchKey] = task;

    final translatedUncached = await task;
    _evictIfNeeded(needed: uncachedTexts.length);

    for (var j = 0; j < uncachedIndices.length; j++) {
      final idx = uncachedIndices[j];
      final original = normalized[idx];
      final translated =
          j < translatedUncached.length ? translatedUncached[j] : original;
      results[idx] = translated;
      _cache['$sourceLang::$targetLang::$original'] = translated;
    }

    return results;
  }

  static Future<List<Map<String, String>>> getSupportedLanguages({
    String displayLang = 'en',
  }) async {
    try {
      final response = await _dio.get(
        'https://translation.googleapis.com/language/translate/v2/languages',
        queryParameters: <String, dynamic>{
          'key': _apiKey,
          'target': displayLang,
          'model': 'nmt',
        },
      );

      final data = response.data;
      if (data is Map &&
          data['data'] is Map &&
          (data['data'] as Map)['languages'] is List) {
        final seenCodes = <String>{};
        final languages = ((data['data'] as Map)['languages'] as List)
            .whereType<Map>()
            .map((item) {
              final rawCode = item['language']?.toString().trim() ?? '';
              final code = rawCode.split('-').first;
              final name =
                  item['name']?.toString().trim() ?? code.toUpperCase();
              if (code.isEmpty || seenCodes.contains(code)) return null;
              seenCodes.add(code);

              final fallback = AppConstants.supportedLanguages.firstWhere(
                (l) => l['code'] == code,
                orElse: () => <String, String>{},
              );

              return <String, String>{
                'code': code,
                'name': fallback['name'] ?? name,
                'native': fallback['native'] ?? name,
                'flag': fallback['flag'] ?? code.toUpperCase(),
              };
            })
            .whereType<Map<String, String>>()
            .toList();

        if (languages.isNotEmpty) {
          languages.sort((a, b) {
            if (a['code'] == 'en') return -1;
            if (b['code'] == 'en') return 1;
            return (a['name'] ?? '').compareTo(b['name'] ?? '');
          });
          return languages;
        }
      }
    } catch (_) {
      // Fall through to bundled list
    }
    return AppConstants.supportedLanguages;
  }

  static Future<String> _translateViaGoogle({
    required String text,
    required String targetLang,
    required String sourceLang,
  }) async {
    final response = await _dio.post(
      _googleTranslateUrl,
      queryParameters: {'key': _apiKey},
      data: <String, dynamic>{
        'q': text,
        'target': targetLang,
        'source': sourceLang,
        'format': 'text',
      },
    );
    return _extractTranslatedText(response.data, fallback: text);
  }

  static Future<String> _translateViaProxy({
    required String text,
    required String targetLang,
    required String sourceLang,
  }) async {
    final response = await _dio.post(
      _proxyUrl,
      data: <String, dynamic>{
        'q': text,
        'target': targetLang,
        'source': sourceLang,
        'format': 'text',
      },
    );
    return _extractTranslatedText(response.data, fallback: text);
  }

  static Future<List<String>> _translateBatch({
    required List<String> texts,
    required String targetLang,
    required String sourceLang,
  }) async {
    try {
      if (_proxyUrl.trim().isNotEmpty) {
        final response = await _dio.post(
          _proxyUrl,
          data: <String, dynamic>{
            'q': texts,
            'target': targetLang,
            'source': sourceLang,
            'format': 'text',
          },
        );
        final extracted = _extractTranslatedTexts(response.data);
        if (extracted.length == texts.length) return extracted;
      }

      final response = await _dio.post(
        _googleTranslateUrl,
        queryParameters: {'key': _apiKey},
        data: <String, dynamic>{
          'q': texts,
          'target': targetLang,
          'source': sourceLang,
          'format': 'text',
        },
      );
      final extracted = _extractTranslatedTexts(response.data);
      if (extracted.length == texts.length) return extracted;
    } catch (_) {
      // Fall back to originals
    }
    return texts;
  }

  static void _evictIfNeeded({int needed = 1}) {
    final overBy = (_cache.length + needed) - _maxCacheSize;
    if (overBy <= 0) return;
    final keysToRemove = _cache.keys.take(overBy).toList();
    keysToRemove.forEach(_cache.remove);
  }

  static String _extractTranslatedText(dynamic data,
      {required String fallback}) {
    if (data is Map) {
      String? translated =
          data['translatedText']?.toString() ?? data['translation']?.toString();

      if ((translated == null || translated.trim().isEmpty) &&
          data['data'] is Map) {
        final nested = data['data'] as Map;
        final translations = nested['translations'];
        if (translations is List && translations.isNotEmpty) {
          final first = translations.first;
          if (first is Map) {
            translated = first['translatedText']?.toString();
          }
        }
      }

      final normalized = translated?.toString().trim();
      if (normalized != null && normalized.isNotEmpty) {
        return _unescapeBasicHtml(normalized);
      }
    }
    return fallback;
  }

  static List<String> _extractTranslatedTexts(dynamic data) {
    if (data is Map && data['data'] is Map) {
      final nested = data['data'] as Map;
      final translations = nested['translations'];
      if (translations is List) {
        return translations
            .map((item) {
              if (item is Map) {
                final value = item['translatedText']?.toString().trim();
                if (value != null && value.isNotEmpty) {
                  return _unescapeBasicHtml(value);
                }
              }
              return '';
            })
            .where((v) => v.isNotEmpty)
            .toList();
      }
    }

    final single = _extractTranslatedText(data, fallback: '');
    return single.isEmpty ? const [] : [single];
  }

  static String _unescapeBasicHtml(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}
