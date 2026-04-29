import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/translation_service.dart';

class TranslatorUtil {
  /// Cloud-only mode is enabled by default for production consistency.
  /// Set --dart-define=TRANSLATION_CLOUD_ONLY=false to allow ML Kit fallback.
  static const bool _cloudOnly = bool.fromEnvironment(
    'TRANSLATION_CLOUD_ONLY',
    defaultValue: true,
  );

  static const Set<String> _mlKitSupported = <String>{'ta', 'hi', 'te', 'kn'};

  static final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  static final Map<String, Map<String, String>> _cacheByLang =
      <String, Map<String, String>>{};
  static final Map<String, Future<String>> _inFlight =
      <String, Future<String>>{};
  static final Map<String, OnDeviceTranslator> _translatorPool =
      <String, OnDeviceTranslator>{};
  static final Set<String> _downloadedModelCodes = <String>{};

  static bool isMlKitSupported(String code) => _mlKitSupported.contains(code);

  static TranslateLanguage? _getMlKitLanguage(String code) {
    switch (code) {
      case 'ta':
        return TranslateLanguage.tamil;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'te':
        return TranslateLanguage.telugu;
      case 'kn':
        return TranslateLanguage.kannada;
      default:
        return null;
    }
  }

  static Future<void> preloadForLanguage(String langCode) async {
    if (_cloudOnly) return;
    final target = _getMlKitLanguage(langCode);
    if (target == null) return;
    await _ensureModelDownloaded(target);
    _translatorPool.putIfAbsent(
      langCode,
      () => OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: target,
      ),
    );
  }

  static Future<void> preloadModels() async {
    if (_cloudOnly) return;
    await Future.wait(
      _mlKitSupported.map(preloadForLanguage),
    );
  }

  static Future<String> translate({
    required String text,
    required String langCode,
  }) async {
    if (langCode == 'en') return text;
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return text;

    final langCache =
        _cacheByLang.putIfAbsent(langCode, () => <String, String>{});
    final cached = langCache[normalizedText];
    if (cached != null) return cached;

    final taskKey = '$langCode::$normalizedText';
    final pending = _inFlight[taskKey];
    if (pending != null) return pending;

    final task = _translateInternal(
      text: normalizedText,
      langCode: langCode,
    ).then((translated) {
      langCache[normalizedText] = translated;
      _inFlight.remove(taskKey);
      return translated;
    }).catchError((_) {
      _inFlight.remove(taskKey);
      return text;
    });

    _inFlight[taskKey] = task;
    return task;
  }

  static Future<String> _translateInternal({
    required String text,
    required String langCode,
  }) async {
    if (langCode == 'en') return text;

    // Cloud-first for every non-English language (including Malayalam).
    final cloudTranslated = await TranslationService.translateCached(
      text: text,
      targetLang: langCode,
    );
    if (cloudTranslated.trim().isNotEmpty && cloudTranslated != text) {
      return cloudTranslated;
    }

    // Optional fallback to ML Kit only when cloud-only mode is disabled.
    if (!_cloudOnly && isMlKitSupported(langCode)) {
      final targetLang = _getMlKitLanguage(langCode);
      if (targetLang != null) {
        try {
          await _ensureModelDownloaded(targetLang);
          final translator = _translatorPool.putIfAbsent(
            langCode,
            () => OnDeviceTranslator(
              sourceLanguage: TranslateLanguage.english,
              targetLanguage: targetLang,
            ),
          );
          final translated = await translator.translateText(text);
          if (translated.trim().isNotEmpty) return translated;
        } catch (_) {
          // Automatic fallback below: ML Kit -> API.
        }
      }
    }

    return text;
  }

  static Future<void> _ensureModelDownloaded(TranslateLanguage target) async {
    final modelCode = target.bcpCode;
    if (_downloadedModelCodes.contains(modelCode)) return;

    final alreadyPresent = await _modelManager.isModelDownloaded(modelCode);
    if (!alreadyPresent) {
      await _modelManager.downloadModel(
        modelCode,
        isWifiRequired: false,
      );
    }
    _downloadedModelCodes.add(modelCode);
  }

  static Future<void> clearCache() async {
    _cacheByLang.clear();
    _inFlight.clear();
  }

  static Future<void> dispose() async {
    for (final translator in _translatorPool.values) {
      await translator.close();
    }
    _translatorPool.clear();
    _downloadedModelCodes.clear();
    await clearCache();
  }

  static Future<List<String>> translateBatch({
    required List<String> texts,
    required String langCode,
  }) async {
    if (texts.isEmpty) return const <String>[];
    if (langCode == 'en') return texts;

    if (_cloudOnly) {
      return TranslationService.translateBatchCached(
        texts: texts,
        targetLang: langCode,
      );
    }

    return Future.wait(
      texts.map((text) => translate(text: text, langCode: langCode)),
    );
  }
}
