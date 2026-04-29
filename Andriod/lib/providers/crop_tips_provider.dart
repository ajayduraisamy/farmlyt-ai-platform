import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../models/app_models.dart';
import '../utils/translator_util.dart';
import 'locale_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class CropTip {
  final String cropSubName;
  final String tipTitle;
  final String tipDescription;

  const CropTip({
    required this.cropSubName,
    required this.tipTitle,
    required this.tipDescription,
  });

  factory CropTip.fromJson(Map<String, dynamic> json) => CropTip(
        cropSubName: (json['crop_sub_name']?.toString() ?? '').trim(),
        tipTitle: (json['tip_title']?.toString() ?? '').trim(),
        tipDescription: (json['tip_description']?.toString() ?? '').trim(),
      );
}

// ─── State ────────────────────────────────────────────────────────────────────
class CropTipsState {
  final List<CropTip> tips;
  final bool isLoading;
  final String? error;
  final String? loadedForCrop; // tracks which crop tips were last loaded for

  const CropTipsState({
    this.tips = const [],
    this.isLoading = false,
    this.error,
    this.loadedForCrop,
  });

  CropTipsState copyWith({
    List<CropTip>? tips,
    bool? isLoading,
    String? error,
    String? loadedForCrop,
    bool clearError = false,
  }) =>
      CropTipsState(
        tips: tips ?? this.tips,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        loadedForCrop: loadedForCrop ?? this.loadedForCrop,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class CropTipsNotifier extends Notifier<CropTipsState> {
  @override
  CropTipsState build() => const CropTipsState();

  /// Call once when entering a crop screen.
  /// Skips the network call if tips for this crop are already loaded.
  Future<void> fetchForCrop(String cropKey, {bool force = false}) async {
    final normalized = _normalize(cropKey);
    final langCode = ref.read(localeProvider).languageCode;

    // Avoid repeated API calls for the same crop
    if (!force &&
        state.loadedForCrop == normalized &&
        !state.isLoading &&
        state.error == null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getCropTips();

      if (res.isSuccess && res.data != null) {
        // Filter only tips matching this crop
        final filtered = res.data!.where((tip) {
          final tipVariants = _variantsFor(tip.cropSubName);
          final cropVariants = _variantsFor(cropKey);

          final intersects = tipVariants.intersection(cropVariants).isNotEmpty;
          if (intersects) {
            return true;
          }

          return tipVariants.any(
                (tipValue) => cropVariants.any(
                  (cropValue) =>
                      tipValue.contains(cropValue) || cropValue.contains(tipValue),
                ),
              );
        }).toList();

        final translated = await Future.wait(
          filtered.map((tip) async {
            final translatedTitle = await TranslatorUtil.translate(
              text: tip.tipTitle,
              langCode: langCode,
            );
            final translatedDescription = await TranslatorUtil.translate(
              text: tip.tipDescription,
              langCode: langCode,
            );
            return CropTip(
              cropSubName: tip.cropSubName,
              tipTitle: translatedTitle,
              tipDescription: translatedDescription,
            );
          }),
        );

        state = state.copyWith(
          tips: translated,
          isLoading: false,
          loadedForCrop: normalized,
        );
      } else {
        state = state.copyWith(
          tips: const [],
          isLoading: false,
          error: res.error,
          loadedForCrop: normalized,
        );
      }
    } catch (e) {
      state = state.copyWith(
        tips: const [],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clear() => state = const CropTipsState();

  Future<void> reloadOnLanguageChange() async {
    if (state.loadedForCrop == null || state.loadedForCrop!.isEmpty) {
      return;
    }
    await fetchForCrop(state.loadedForCrop!, force: true);
  }

  static String _normalize(String value) {
    final raw = value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    final normalized = DetectionCategory.normalizeCropKey(raw);
    const aliases = <String, String>{
      'lady_finger': 'ladyfinger',
      'lady_fingers': 'ladyfinger',
      'ladys_finger': 'ladyfinger',
      'ladys_fingers': 'ladyfinger',
      'bhindi': 'ladyfinger',
      'okra': 'ladyfinger',
      'okra_plant': 'ladyfinger',
      'okra_leaf': 'ladyfinger',
    };

    return aliases[normalized] ?? aliases[raw] ?? normalized;
  }

  static Set<String> _variantsFor(String value) {
    final normalized = _normalize(value);
    final variants = <String>{
      normalized,
      normalized.replaceAll('_', ''),
      normalized.replaceAll('_', ' '),
    };

    if (normalized == 'ladyfinger') {
      variants.addAll({
        'lady_finger',
        'lady finger',
        'ladys_finger',
        'ladys finger',
        'okra',
        'bhindi',
      });
    }

    return variants.where((item) => item.trim().isNotEmpty).toSet();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
// Use .family so each crop screen gets its own isolated state
final cropTipsProvider =
    NotifierProvider<CropTipsNotifier, CropTipsState>(CropTipsNotifier.new);
