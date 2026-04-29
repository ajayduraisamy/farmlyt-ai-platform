import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/translation_service.dart';
import '../utils/translator_util.dart';
import 'locale_provider.dart';

// ── Request types ──────────────────────────────────────────────────────────

class TranslationRequest {
  final String text;
  final String langCode;

  const TranslationRequest({
    required this.text,
    required this.langCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationRequest &&
          other.text == text &&
          other.langCode == langCode;

  @override
  int get hashCode => Object.hash(text, langCode);
}

class TranslationBatchRequest {
  final List<String> texts;
  final String langCode;

  const TranslationBatchRequest({
    required this.texts,
    required this.langCode,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TranslationBatchRequest) return false;
    if (other.langCode != langCode) return false;
    if (other.texts.length != texts.length) return false;
    for (var i = 0; i < texts.length; i++) {
      if (texts[i] != other.texts[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(langCode, Object.hashAll(texts));
}

// ── Providers ──────────────────────────────────────────────────────────────

/// Pre-warms translation model for a language code.
final translationWarmupProvider = FutureProvider.family<void, String>(
  (ref, langCode) async => TranslatorUtil.preloadForLanguage(langCode),
);

/// Translate a single string with an explicit langCode.
/// autoDispose: frees memory when the widget using it is disposed.
/// Caching is handled inside TranslatorUtil._cacheByLang — no extra layer needed.
final translatedTextProvider =
    FutureProvider.autoDispose.family<String, TranslationRequest>(
  (ref, request) async {
    if (request.langCode == 'en') return request.text;
    return TranslatorUtil.translate(
      text: request.text,
      langCode: request.langCode,
    );
  },
);

/// Translate a string using the current app locale — auto-updates on
/// language change because it watches [localeProvider].
final translatedCurrentLocaleTextProvider =
    FutureProvider.autoDispose.family<String, String>(
  (ref, text) async {
    final langCode = ref.watch(localeProvider).languageCode;
    if (langCode == 'en') return text;
    return TranslatorUtil.translate(text: text, langCode: langCode);
  },
);

/// Batch translate a list of strings.
final translatedBatchProvider =
    FutureProvider.autoDispose.family<List<String>, TranslationBatchRequest>(
  (ref, request) async {
    if (request.langCode == 'en') return request.texts;
    return TranslatorUtil.translateBatch(
      texts: request.texts,
      langCode: request.langCode,
    );
  },
);

/// Fetches the full list of supported languages from Google Translation API
/// (or bundled fallback). Cached for 7 days — never refetches unnecessarily.
final supportedTranslationLanguagesProvider =
    FutureProvider<List<Map<String, String>>>(
  (ref) async => TranslationService.getSupportedLanguages(),
);
