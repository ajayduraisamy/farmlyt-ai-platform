import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../utils/translator_util.dart';
import 'locale_provider.dart';
import 'auth_provider.dart';

class FarmingTipsState {
  final List<FarmingTip> tips;
  final bool isLoading;
  final bool isLoaded; // true after first successful fetch
  final String? error;

  const FarmingTipsState({
    this.tips = const [],
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
  });

  FarmingTipsState copyWith({
    List<FarmingTip>? tips,
    bool? isLoading,
    bool? isLoaded,
    String? error,
    bool clearError = false,
  }) =>
      FarmingTipsState(
        tips: tips ?? this.tips,
        isLoading: isLoading ?? this.isLoading,
        isLoaded: isLoaded ?? this.isLoaded,
        error: clearError ? null : (error ?? this.error),
      );
}

class FarmingTipsNotifier extends Notifier<FarmingTipsState> {
  // Track last fetched language to skip redundant refetches
  String _lastLangCode = '';

  @override
  FarmingTipsState build() {
    Future.microtask(() => fetch());
    return const FarmingTipsState(isLoading: true);
  }

  Future<void> fetch() async {
    final langCode = ref.read(localeProvider).languageCode;

    // ── Guard: skip if already loaded for this language ──────────────────
    if (state.isLoaded && _lastLangCode == langCode && !state.isLoading) {
      return;
    }

    _lastLangCode = langCode;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.getFarmingTips();

      if (result.isSuccess && result.data != null) {
        final apiTips = result.data!;

        // English or empty list — no translation needed
        if (langCode == 'en' || apiTips.isEmpty) {
          state = state.copyWith(
            tips: apiTips,
            isLoading: false,
            isLoaded: true,
            clearError: true,
          );
          return;
        }

        // ── Batch translate: ONE API call instead of N*2 calls ────────────
        // Flat list format: [title0, desc0, title1, desc1, ...]
        final textsToTranslate = <String>[];
        for (final tip in apiTips) {
          textsToTranslate
            ..add(tip.title)
            ..add(tip.description);
        }

        final translated = await TranslatorUtil.translateBatch(
          texts: textsToTranslate,
          langCode: langCode,
        );

        // Re-assemble with fallback to English if translation is empty
        final translatedTips = List.generate(apiTips.length, (i) {
          final titleIdx = i * 2;
          final descIdx = i * 2 + 1;
          return FarmingTip(
            id: apiTips[i].id,
            title: (titleIdx < translated.length &&
                    translated[titleIdx].isNotEmpty)
                ? translated[titleIdx]
                : apiTips[i].title,
            description:
                (descIdx < translated.length && translated[descIdx].isNotEmpty)
                    ? translated[descIdx]
                    : apiTips[i].description,
          );
        });

        state = state.copyWith(
          tips: translatedTips,
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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

final farmingTipsProvider =
    NotifierProvider<FarmingTipsNotifier, FarmingTipsState>(
  FarmingTipsNotifier.new,
);
