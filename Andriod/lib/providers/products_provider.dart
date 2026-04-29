import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ProductsState {
  final List<CropProduct> crops;
  final bool isLoading;
  final String? error;

  const ProductsState({
    this.crops = const [],
    this.isLoading = false,
    this.error,
  });

  ProductsState copyWith({
    List<CropProduct>? crops,
    bool? isLoading,
    String? error,
  }) =>
      ProductsState(
        crops: crops ?? this.crops,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProductsNotifier extends Notifier<ProductsState> {
  @override
  ProductsState build() {
    Future.microtask(() => fetch());
    return const ProductsState(isLoading: true);
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    final api = ref.read(apiServiceProvider);
    final result = await api.getCropWithProducts();
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(crops: result.data, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
        crops: const [],
      );
    }
  }

  /// Find products for a given crop title + disease name.
  /// Matching is fuzzy: lowercased, underscores/spaces normalised.
  List<ProductRecommendation> findProducts({
    required String cropTitle,
    required String diseaseName,
  }) {
    if (state.crops.isEmpty) return const [];

    final normCrop = _norm(cropTitle);
    final normDisease = _norm(diseaseName);
    final cropVariants = _cropVariants(normCrop);

    // 1. Find the best-matching crop entry (exact/alias first, then fuzzy)
    final exactCropMatches = state.crops.where((c) {
      final candidate = _norm(c.cropTitle);
      return cropVariants.contains(candidate);
    }).toList();

    CropProduct? cropMatch;
    if (exactCropMatches.isNotEmpty) {
      cropMatch = exactCropMatches.first;
    } else {
      for (final candidateCrop in state.crops) {
        final candidate = _norm(candidateCrop.cropTitle);
        if (candidate.contains(normCrop) || normCrop.contains(candidate)) {
          cropMatch = candidateCrop;
          break;
        }
      }
    }
    if (cropMatch == null) return const [];

    // 2. Within that crop, find disease match (exact first, then fuzzy)
    final exactDiseaseMatches = cropMatch.diseases.where((d) {
      final nd = _norm(d.diseaseName);
      return nd == normDisease;
    }).toList();

    DiseaseProduct? diseaseMatch;
    if (exactDiseaseMatches.isNotEmpty) {
      diseaseMatch = exactDiseaseMatches.first;
    } else {
      for (final candidateDisease in cropMatch.diseases) {
        final nd = _norm(candidateDisease.diseaseName);
        if (nd.contains(normDisease) || normDisease.contains(nd)) {
          diseaseMatch = candidateDisease;
          break;
        }
      }
    }
    if (diseaseMatch == null) return const [];

    // 3. Map ProductItem -> ProductRecommendation
    return diseaseMatch.products
        .map((p) => ProductRecommendation(
              productName: p.name,
              productImage: p.image,
              productUrl: p.url,
            ))
        .toList();
  }

  static String _norm(String v) =>
      v.trim().toLowerCase().replaceAll(RegExp(r'[\s_]+'), '_');

  static Set<String> _cropVariants(String normalizedCrop) {
    final variants = <String>{
      normalizedCrop,
      normalizedCrop.replaceAll('_', ''),
    };

    if (normalizedCrop == 'ladyfinger' || normalizedCrop == 'lady_finger') {
      variants.addAll({'ladyfinger', 'lady_finger', 'okra', 'bhindi'});
    }

    return variants;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final productsProvider =
    NotifierProvider<ProductsNotifier, ProductsState>(ProductsNotifier.new);
