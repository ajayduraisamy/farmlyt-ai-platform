/// Maps app language codes → BCP-47 tags understood by Flutter TTS engines.
///
/// Usage:
///   final tag = TtsLanguageMapper.getTtsLanguage('ta'); // 'ta-IN'
///   final candidates = TtsLanguageMapper.getLanguageCandidates('ta');
class TtsLanguageMapper {
  // Static utility — prevent instantiation
  TtsLanguageMapper._();

  static const Map<String, String> _langToTts = {
    'en': 'en-IN',
    'ar': 'ar-SA',
    'bn': 'bn-IN',
    'bg': 'bg-BG',
    'ca': 'ca-ES',
    'cs': 'cs-CZ',
    'da': 'da-DK',
    'de': 'de-DE',
    'el': 'el-GR',
    'es': 'es-ES',
    'et': 'et-EE',
    'fa': 'fa-IR',
    'fi': 'fi-FI',
    'fr': 'fr-FR',
    'gu': 'gu-IN',
    'ta': 'ta-IN',
    'kn': 'kn-IN',
    'hi': 'hi-IN',
    'te': 'te-IN',
    'ml': 'ml-IN',
    'he': 'he-IL',
    'hr': 'hr-HR',
    'hu': 'hu-HU',
    'id': 'id-ID',
    'is': 'is-IS',
    'it': 'it-IT',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'lt': 'lt-LT',
    'lv': 'lv-LV',
    'mr': 'mr-IN',
    'nl': 'nl-NL',
    'no': 'nb-NO',
    'pa': 'pa-IN',
    'pl': 'pl-PL',
    'pt': 'pt-PT',
    'ro': 'ro-RO',
    'ru': 'ru-RU',
    'sk': 'sk-SK',
    'sl': 'sl-SI',
    'sv': 'sv-SE',
    'sw': 'sw-TZ',
    'th': 'th-TH',
    'tr': 'tr-TR',
    'uk': 'uk-UA',
    'ur': 'ur-PK',
    'vi': 'vi-VN',
    'zh': 'zh-CN',
    'zu': 'zu-ZA',
  };

  /// Returns the preferred BCP-47 tag for [langCode].
  /// Falls back to the base code if no exact match, then to [langCode] itself.
  static String getTtsLanguage(String langCode) {
    final normalized = langCode.trim();
    return _langToTts[normalized] ??
        _langToTts[normalized.split('-').first] ??
        normalized;
  }

  /// Returns an ordered list of BCP-47 candidates to try on the device.
  /// TtsService iterates this list and picks the first one the device supports.
  static List<String> getLanguageCandidates(String langCode) {
    final normalized = langCode.trim();
    final base = normalized.split('-').first;
    final preferred = getTtsLanguage(normalized);

    // Ordered set — first match wins in TtsService
    return <String>{
      preferred,
      normalized,
      base,
      '${base.toLowerCase()}-${base.toUpperCase()}',
      'en-IN', // universal fallback
      'en-US',
      'en-GB',
    }.where((v) => v.trim().isNotEmpty).toList(growable: false);
  }
}
