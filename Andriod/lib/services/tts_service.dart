import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../utils/tts_language_mapper.dart';
import '../utils/translator_util.dart';

/// Production-ready TTS service.
///
/// Key improvements:
///  • Singleton FlutterTts — no repeated init cost per speak() call
///  • Language availability checked ONCE and cached — avoids per-call
///    getLanguages() which is a platform channel call (~10-30 ms each)
///  • Text is translated to selected language before speaking so ALL
///    content (including API-fetched disease names, recommendations,
///    farming tips) is spoken in the correct language
///  • Graceful fallback chain: preferred locale → base code → en-IN
class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  // Cache available languages — fetching the full list is expensive
  static List<String>? _availableLanguages;

  // ── Init ───────────────────────────────────────────────────────────────

  static Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(false);

    // Pre-fetch supported languages once and cache them
    try {
      final langs = await _tts.getLanguages as List?;
      _availableLanguages = langs?.cast<String>() ?? const [];
    } catch (_) {
      _availableLanguages = const [];
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Speak [text] in [langCode].
  ///
  /// Set [translate] to false only if [text] is already in [langCode]
  /// (e.g. tips that were pre-translated by farming_tips_provider).
  static Future<void> speak({
    required String text,
    required String langCode,
    bool translate = true,
  }) async {
    await _init();

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // ── 1. Translate to target language ───────────────────────────────
    String speakText = trimmed;
    if (translate && langCode != 'en') {
      try {
        final result = await TranslatorUtil.translate(
          text: trimmed,
          langCode: langCode,
        );
        if (result.trim().isNotEmpty) speakText = result;
      } catch (e) {
        debugPrint('TTS translate error: $e — speaking original');
      }
    }

    // ── 2. Pick best available TTS locale ─────────────────────────────
    final lang = await _resolveTtsLanguage(langCode);

    // ── 3. Speak ──────────────────────────────────────────────────────
    await _tts.setLanguage(lang);
    await _tts.speak(speakText);
  }

  /// Speak a list of strings joined and translated.
  static Future<void> speakList({
    required List<String> texts,
    required String langCode,
    String separator = '. ',
    bool translate = true,
  }) async {
    final combined =
        texts.map((t) => t.trim()).where((t) => t.isNotEmpty).join(separator);
    if (combined.isEmpty) return;
    await speak(text: combined, langCode: langCode, translate: translate);
  }

  static Future<void> stop() async {
    await _init();
    await _tts.stop();
  }

  static Future<void> pause() async {
    await _init();
    await _tts.pause();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Resolves the best available TTS language for [langCode].
  /// Uses cached [_availableLanguages] — no repeated platform calls.
  static Future<String> _resolveTtsLanguage(String langCode) async {
    await _init();

    final available = _availableLanguages ?? const [];
    if (available.isEmpty) return 'en-IN';

    final candidates = TtsLanguageMapper.getLanguageCandidates(langCode);

    for (final candidate in candidates) {
      final match = available.any(
        (l) => l.toLowerCase().startsWith(candidate.toLowerCase()),
      );
      if (match) return candidate;
    }

    return 'en-IN'; // hard fallback
  }
}
