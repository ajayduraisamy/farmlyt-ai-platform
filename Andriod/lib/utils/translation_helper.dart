import 'package:flutter/material.dart';
import '../utils/translator_util.dart';
import '../l10n/app_localizations.dart';

/// Helper that translates arbitrary text coming from the API into
/// the currently active language.  Use this for any content that is
/// fetched from the backend and NOT covered by the static
/// AppLocalizations keys — e.g. farming tip titles/bodies, category
/// titles from the backend, disease names, fertilizer/pesticide lists.
class TranslationHelper {
  /// Translate a single string to [langCode].
  /// Returns the original text if translation fails or is not needed.
  static Future<String> translate(String text, String langCode) async {
    if (langCode == 'en') return text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    try {
      return await TranslatorUtil.translate(text: trimmed, langCode: langCode);
    } catch (_) {
      return text;
    }
  }

  /// Translate a list of strings to [langCode] in a single batch call.
  static Future<List<String>> translateList(
      List<String> texts, String langCode) async {
    if (langCode == 'en') return texts;
    if (texts.isEmpty) return texts;
    try {
      return await TranslatorUtil.translateBatch(
          texts: texts, langCode: langCode);
    } catch (_) {
      return texts;
    }
  }

  /// Translate a map of string values to [langCode].
  static Future<Map<String, String>> translateMap(
      Map<String, String> map, String langCode) async {
    if (langCode == 'en') return map;
    if (map.isEmpty) return map;
    final keys = map.keys.toList();
    final values = map.values.toList();
    final translated = await translateList(values, langCode);
    final result = <String, String>{};
    for (var i = 0; i < keys.length; i++) {
      result[keys[i]] = i < translated.length ? translated[i] : values[i];
    }
    return result;
  }

  /// Get the current language code from context.
  static String langCode(BuildContext context) =>
      Localizations.localeOf(context).languageCode;
}

/// A widget that translates a text string to the current locale language
/// and rebuilds automatically when the locale changes.
///
/// Usage:
/// ```dart
/// TranslatedText(
///   text: tip.title,  // English text from API
///   style: GoogleFonts.nunito(...),
/// )
/// ```
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const TranslatedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _displayText = '';
  String? _lastLang;
  String? _lastInput;

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _lastLang || widget.text != _lastInput) {
      _lastLang = lang;
      _lastInput = widget.text;
      _translate(lang);
    }
  }

  @override
  void didUpdateWidget(TranslatedText old) {
    super.didUpdateWidget(old);
    final lang = Localizations.localeOf(context).languageCode;
    if (widget.text != old.text || lang != _lastLang) {
      _lastLang = lang;
      _lastInput = widget.text;
      _translate(lang);
    }
  }

  Future<void> _translate(String lang) async {
    if (lang == 'en' || widget.text.trim().isEmpty) {
      if (mounted) setState(() => _displayText = widget.text);
      return;
    }
    final result = await TranslationHelper.translate(widget.text, lang);
    if (mounted) setState(() => _displayText = result);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap,
    );
  }
}

/// Variant of [TranslatedText] that uses AppLocalizations.t() first
/// (for hardcoded keys) and falls back to cloud translation for
/// any API-sourced text not in the static map.
class SmartTranslatedText extends StatefulWidget {
  final String text;
  final String? localizationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const SmartTranslatedText({
    super.key,
    required this.text,
    this.localizationKey,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  @override
  State<SmartTranslatedText> createState() => _SmartTranslatedTextState();
}

class _SmartTranslatedTextState extends State<SmartTranslatedText> {
  String _displayText = '';
  String? _lastLang;
  String? _lastInput;

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _lastLang || widget.text != _lastInput) {
      _lastLang = lang;
      _lastInput = widget.text;
      _resolveText(context, lang);
    }
  }

  @override
  void didUpdateWidget(SmartTranslatedText old) {
    super.didUpdateWidget(old);
    final lang = Localizations.localeOf(context).languageCode;
    if (widget.text != old.text || lang != _lastLang) {
      _lastLang = lang;
      _lastInput = widget.text;
      _resolveText(context, lang);
    }
  }

  void _resolveText(BuildContext context, String lang) {
    // 1. Try static localizations key first
    if (widget.localizationKey != null) {
      try {
        final l = AppLocalizations.of(context);
        final localized = l.t(widget.localizationKey!);
        if (localized != widget.localizationKey) {
          if (mounted) setState(() => _displayText = localized);
          return;
        }
      } catch (_) {}
    }

    // 2. Cloud translate API-sourced text
    if (lang == 'en' || widget.text.trim().isEmpty) {
      if (mounted) setState(() => _displayText = widget.text);
      return;
    }
    TranslationHelper.translate(widget.text, lang).then((result) {
      if (mounted) setState(() => _displayText = result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap,
    );
  }
}
