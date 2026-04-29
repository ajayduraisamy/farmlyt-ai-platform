import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../utils/translator_util.dart';
import 'locale_provider.dart';
import 'auth_provider.dart';

class CategoriesState {
  final List<DetectionCategory> categories;
  final bool isLoading;
  final bool isLoaded; // true once at least one successful fetch completed
  final String? error;

  const CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
  });

  CategoriesState copyWith({
    List<DetectionCategory>? categories,
    bool? isLoading,
    bool? isLoaded,
    String? error,
    bool clearError = false,
  }) =>
      CategoriesState(
        categories: categories ?? this.categories,
        isLoading: isLoading ?? this.isLoading,
        isLoaded: isLoaded ?? this.isLoaded,
        error: clearError ? null : (error ?? this.error),
      );
}

class CategoriesNotifier extends Notifier<CategoriesState> {
  int? _lastAgriId;
  String _lastLangCode = '';

  @override
  CategoriesState build() {
    // Trigger initial load without blocking the provider build
    Future.microtask(() => fetch());
    return const CategoriesState(isLoading: true);
  }

  Future<void> fetch({int? agriId}) async {
    final langCode = ref.read(localeProvider).languageCode;

    // ── Guard: skip if data is fresh for the same agriId + language ─────────
    if (state.isLoaded &&
        _lastAgriId == agriId &&
        _lastLangCode == langCode &&
        !state.isLoading) {
      return;
    }

    _lastAgriId = agriId;
    _lastLangCode = langCode;

    state = state.copyWith(isLoading: true, clearError: true);

    final api = ref.read(apiServiceProvider);
    final result = await api.getCategories(agriId: agriId);

    if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
      // Only translate if the language is not English
      final translated = langCode == 'en'
          ? result.data!
          : await _translateCategories(result.data!, langCode);

      state = state.copyWith(
        categories: translated,
        isLoading: false,
        isLoaded: true,
        clearError: true,
      );
    } else {
      // Keep stale data visible if we have it — only update error
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Force re-fetch regardless of cache/flags (e.g. pull-to-refresh).
  Future<void> refetch() {
    // Reset isLoaded so guard is bypassed
    state = state.copyWith(isLoaded: false);
    return fetch(agriId: _lastAgriId);
  }

  /// Called by locale_provider when the user changes language.
  Future<void> reloadOnLanguageChange() {
    state = state.copyWith(isLoaded: false);
    return fetch(agriId: _lastAgriId);
  }

  // ── Translation helper ────────────────────────────────────────────────────
  Future<List<DetectionCategory>> _translateCategories(
    List<DetectionCategory> categories,
    String langCode,
  ) async {
    return Future.wait(
      categories.map((category) async {
        // Translate category title
        final translatedTitle = await TranslatorUtil.translate(
          text: category.title,
          langCode: langCode,
        );

        // Translate all crop option titles in a single batch call
        if (category.cropOptions.isEmpty) {
          return category.copyWith(title: translatedTitle);
        }

        final optionTitles = category.cropOptions.map((o) => o.title).toList();
        final translatedTitles = await TranslatorUtil.translateBatch(
          texts: optionTitles,
          langCode: langCode,
        );

        final translatedOptions =
            List.generate(category.cropOptions.length, (i) {
          return category.cropOptions[i].copyWith(
            title: i < translatedTitles.length && translatedTitles[i].isNotEmpty
                ? translatedTitles[i]
                : category.cropOptions[i].title,
          );
        });

        return category.copyWith(
          title: translatedTitle,
          cropOptions: translatedOptions,
        );
      }),
    );
  }
}

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, CategoriesState>(
  CategoriesNotifier.new,
);
