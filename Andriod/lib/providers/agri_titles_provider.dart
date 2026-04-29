import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../utils/translator_util.dart';
import 'locale_provider.dart';
import 'auth_provider.dart';

class AgriTitlesState {
  final List<AgriTitle> agriTitles;
  final bool isLoading;
  final bool isLoaded; // true after first successful fetch
  final String? error;

  const AgriTitlesState({
    this.agriTitles = const [],
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
  });

  AgriTitlesState copyWith({
    List<AgriTitle>? agriTitles,
    bool? isLoading,
    bool? isLoaded,
    String? error,
    bool clearError = false,
  }) =>
      AgriTitlesState(
        agriTitles: agriTitles ?? this.agriTitles,
        isLoading: isLoading ?? this.isLoading,
        isLoaded: isLoaded ?? this.isLoaded,
        error: clearError ? null : (error ?? this.error),
      );
}

class AgriTitlesNotifier extends Notifier<AgriTitlesState> {
  String _lastLangCode = '';

  @override
  AgriTitlesState build() {
    Future.microtask(() => fetch());
    return const AgriTitlesState(isLoading: true);
  }

  Future<void> fetch() async {
    final langCode = ref.read(localeProvider).languageCode;

    // ── Guard: skip if already loaded for this language ──────────────────
    if (state.isLoaded && _lastLangCode == langCode && !state.isLoading) {
      return;
    }

    _lastLangCode = langCode;
    state = state.copyWith(isLoading: true, clearError: true);

    final api = ref.read(apiServiceProvider);
    final result = await api.getAgriTitles();

    if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
      // English — no translation needed
      if (langCode == 'en') {
        state = state.copyWith(
          agriTitles: result.data!,
          isLoading: false,
          isLoaded: true,
          clearError: true,
        );
        return;
      }

      final translated = await Future.wait(
        result.data!.map((item) async {
          final title = await TranslatorUtil.translate(
            text: item.title,
            langCode: langCode,
          );
          return AgriTitle(
            id: item.id,
            title: title,
            imageUrl: item.imageUrl,
            createdAt: item.createdAt,
          );
        }),
      );

      state = state.copyWith(
        agriTitles: translated,
        isLoading: false,
        isLoaded: true,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Force re-fetch bypassing the isLoaded guard (pull-to-refresh).
  Future<void> refetch() {
    state = state.copyWith(isLoaded: false);
    return fetch();
  }

  /// Called by locale_provider when the user changes language.
  Future<void> reloadOnLanguageChange() {
    state = state.copyWith(isLoaded: false);
    return fetch();
  }
}

final agriTitlesProvider =
    NotifierProvider<AgriTitlesNotifier, AgriTitlesState>(
  AgriTitlesNotifier.new,
);
