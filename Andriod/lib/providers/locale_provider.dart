import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_constants.dart';
import '../utils/translator_util.dart';
import 'auth_provider.dart';
import 'agri_titles_provider.dart';
import 'categories_provider.dart';
import 'crop_tips_provider.dart';
import 'farming_tips_provider.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedLang = prefs.getString(AppConstants.keyLanguage) ?? 'en';

    // Warm up translation model in background — does not block build()
    Future.microtask(() => TranslatorUtil.preloadForLanguage(savedLang));

    return Locale(savedLang);
  }

  Future<void> setLocale(String languageCode) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(AppConstants.keyLanguage, languageCode);

      // Update UI locale immediately — triggers AppLocalizations reload
      state = Locale(languageCode);

      // Warm up translation model for the new language
      await TranslatorUtil.preloadForLanguage(languageCode);

      // Small delay to let the locale propagate before re-fetching data
      await Future.delayed(const Duration(milliseconds: 200));

      // ── Reload ALL translated content in parallel ─────────────────────
      // Sequential awaits here would mean 4× the wait time. Future.wait
      // fires all four simultaneously and waits for the last to finish.
      await Future.wait([
        ref.read(farmingTipsProvider.notifier).reloadOnLanguageChange(),
        ref.read(agriTitlesProvider.notifier).reloadOnLanguageChange(),
        ref.read(categoriesProvider.notifier).reloadOnLanguageChange(),
        ref.read(cropTipsProvider.notifier).reloadOnLanguageChange(),
      ]);

      debugPrint('🌐 Language changed to: $languageCode');
    } catch (e) {
      debugPrint('❌ Language change failed: $e');
    }
  }

  String get currentLanguageCode => state.languageCode;

  String get currentLanguageName {
    final lang = AppConstants.supportedLanguages.firstWhere(
      (l) => l['code'] == state.languageCode,
      orElse: () => {
        'name': 'English',
        'code': 'en',
        'native': 'English',
        'flag': '🇬🇧',
      },
    );
    return lang['native'] ?? lang['name'] ?? 'English';
  }

  Future<void> refreshAllTranslations() => Future.wait([
        ref.read(farmingTipsProvider.notifier).reloadOnLanguageChange(),
        ref.read(agriTitlesProvider.notifier).reloadOnLanguageChange(),
        ref.read(categoriesProvider.notifier).reloadOnLanguageChange(),
        ref.read(cropTipsProvider.notifier).reloadOnLanguageChange(),
      ]);
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
