/// Formats text from the API / translation layer for clean Flutter rendering.
///
/// Responsibilities:
///  • Insert zero-width-space break points inside very long words
///    (e.g. compound scientific/disease names) so Flutter can wrap them.
///  • Collapse excessive whitespace.
///  • Truncate with ellipsis when a hard character limit is needed.
///  • Title-case helper for crop/category names.
class ApiTextFormatter {
  // Private constructor — static utility class
  ApiTextFormatter._();

  /// Format text for general display.
  /// Long words receive [U+200B] zero-width spaces at [longWordChunk]
  /// character intervals so Flutter's text engine can line-wrap them.
  static String format(String text, {int longWordChunk = 14}) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return normalized;

    final buffer = StringBuffer();
    final words = normalized.split(' ');
    for (var i = 0; i < words.length; i++) {
      if (i > 0) buffer.write(' ');
      buffer.write(_breakLongWord(words[i], longWordChunk));
    }
    return buffer.toString();
  }

  /// Format text for use inside a button where horizontal space is limited.
  /// Shorter chunk (10) handles long translated words in narrow buttons.
  static String formatButton(String text) => format(text, longWordChunk: 10);

  /// Truncate to [maxChars] characters and append '…' if needed.
  static String truncate(String text, {int maxChars = 80}) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= maxChars) return normalized;
    return '${normalized.substring(0, maxChars).trimRight()}…';
  }

  /// Title-case every word: "ridge gourd" → "Ridge Gourd".
  static String titleCase(String text) {
    return text.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  // ── Internal ─────────────────────────────────────────────────────────

  static String _breakLongWord(String word, int chunkLength) {
    if (word.length <= chunkLength) return word;

    final buffer = StringBuffer();
    for (var i = 0; i < word.length; i += chunkLength) {
      final end =
          (i + chunkLength < word.length) ? i + chunkLength : word.length;
      buffer.write(word.substring(i, end));
      if (end < word.length) {
        buffer.write('\u200B'); // zero-width space — safe line-break hint
      }
    }
    return buffer.toString();
  }
}
