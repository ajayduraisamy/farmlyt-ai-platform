import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../utils/translator_util.dart';
import '../utils/app_constants.dart';
import 'auth_provider.dart';
import 'locale_provider.dart';
import 'products_provider.dart';
import 'wallet_provider.dart';

class DetectionState {
  final DetectionResult? result;
  final bool isLoading;
  final String? error;
  final File? selectedImage;
  final String? selectedCropKey;

  const DetectionState({
    this.result,
    this.isLoading = false,
    this.error,
    this.selectedImage,
    this.selectedCropKey,
  });

  DetectionState copyWith({
    DetectionResult? result,
    bool? isLoading,
    String? error,
    File? selectedImage,
    String? selectedCropKey,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      DetectionState(
        result: clearResult ? null : (result ?? this.result),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        selectedImage: selectedImage ?? this.selectedImage,
        selectedCropKey: selectedCropKey ?? this.selectedCropKey,
      );
}

class DetectionNotifier extends Notifier<DetectionState> {
  Timer? _syncTimer;

  @override
  DetectionState build() {
    ref.onDispose(() => _syncTimer?.cancel());
    return const DetectionState();
  }

  void setImage(File image) {
    _syncTimer?.cancel();
    state = state.copyWith(
        selectedImage: image, clearResult: true, clearError: true);
  }

  void selectCrop(String cropKey) {
    _syncTimer?.cancel();
    state = state.copyWith(
        selectedCropKey: cropKey, clearResult: true, clearError: true);
  }

  void clearAll() {
    _syncTimer?.cancel();
    state = const DetectionState();
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (state.result == null || state.selectedCropKey == null) {
        timer.cancel();
        return;
      }

      final products = ref.read(productsProvider.notifier).findProducts(
            cropTitle: state.selectedCropKey!,
            diseaseName: state.result!.diseaseName,
          );

      if (products.isNotEmpty &&
          products.length != (state.result?.products.length ?? 0)) {
        final localizedProducts = await _translateProducts(products);
        state = state.copyWith(
          result: state.result!.copyWith(products: localizedProducts),
        );
      }
    });
  }

  Future<bool> analyze({required String categoryPath}) async {
    if (state.selectedImage == null || state.selectedCropKey == null) {
      state =
          state.copyWith(error: 'Please select a crop and upload an image.');
      return false;
    }

    final userId = ref.read(authProvider).user?.id ?? '';
    if (userId.isEmpty) {
      state = state.copyWith(error: 'Please login again to continue scanning.');
      return false;
    }

    final walletState = ref.read(walletProvider);
    final availableCredits = walletState.credits > 0
        ? walletState.credits
        : (ref.read(authProvider).user?.credits ?? 0);

    if (availableCredits < AppConstants.creditsPerScan) {
      state = state.copyWith(
        error: 'Insufficient credits. You need ${AppConstants.creditsPerScan}'
            ' credits per scan. Current balance: $availableCredits.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final startTime = DateTime.now();
    final api = ref.read(apiServiceProvider);

    final result = await api.detectDisease(
      imageFile: state.selectedImage!,
      category: categoryPath,
      cropKey: state.selectedCropKey!,
      userId: userId,
    );

    final apiTime = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('[Detection] API call took ${apiTime}ms');

    if (result.isSuccess && result.data != null) {
      var finalResult = result.data!;
      if (finalResult.products.isEmpty) {
        final products = ref.read(productsProvider.notifier).findProducts(
              cropTitle: state.selectedCropKey!,
              diseaseName: finalResult.diseaseName,
            );
        if (products.isNotEmpty) {
          finalResult = finalResult.copyWith(products: products);
        }
      }

      state = state.copyWith(result: finalResult, isLoading: false);
      debugPrint(
          '[Detection] Results displayed after ${DateTime.now().difference(startTime).inMilliseconds}ms');

      unawaited(_translateCurrentResult(finalResult));
      _startAutoSync();
      ref
          .read(walletProvider.notifier)
          .spendCredits(AppConstants.creditsPerScan);
      unawaited(
        ref.read(authProvider.notifier).deductCredits().catchError((_) {}),
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
      return false;
    }
  }

  Future<void> _translateCurrentResult(DetectionResult sourceResult) async {
    final translated = await _translateDetectionResult(sourceResult);
    if (translated == sourceResult || state.result != sourceResult) {
      return;
    }
    state = state.copyWith(result: translated);
  }

  Future<DetectionResult> _translateDetectionResult(
      DetectionResult result) async {
    final langCode = ref.read(localeProvider).languageCode;
    if (langCode == 'en') return result;

    try {
      final startTime = DateTime.now();
      // Run all translations in parallel to reduce total time from ~8-12s to ~2-3s
      final results = await Future.wait<dynamic>([
        TranslatorUtil.translate(
          text: result.diseaseName,
          langCode: langCode,
        ),
        TranslatorUtil.translate(
          text: result.description,
          langCode: langCode,
        ),
        TranslatorUtil.translate(
          text: result.predictionText,
          langCode: langCode,
        ),
        TranslatorUtil.translateBatch(
          texts: result.fertilizers,
          langCode: langCode,
        ),
        TranslatorUtil.translateBatch(
          texts: result.pesticides,
          langCode: langCode,
        ),
        TranslatorUtil.translateBatch(
          texts: result.actionSteps,
          langCode: langCode,
        ),
        _translateProducts(
          result.products,
          langCode: langCode,
        ),
      ]);

      final translateTime = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('[Translation] All translations took ${translateTime}ms');

      return result.copyWith(
        diseaseName: results[0] as String,
        description: results[1] as String,
        predictionText: results[2] as String,
        fertilizers: results[3] as List<String>,
        pesticides: results[4] as List<String>,
        actionSteps: results[5] as List<String>,
        products: results[6] as List<ProductRecommendation>,
      );
    } catch (_) {
      // Graceful fallback: keep original English result.
      return result;
    }
  }

  Future<void> refreshCurrentResultProducts() async {
    final currentResult = state.result;
    final selectedCropKey = state.selectedCropKey;
    if (currentResult == null || selectedCropKey == null) {
      return;
    }

    final products = ref.read(productsProvider.notifier).findProducts(
          cropTitle: selectedCropKey,
          diseaseName: currentResult.diseaseName,
        );
    if (products.isEmpty) {
      return;
    }

    final localizedProducts = await _translateProducts(products);
    state = state.copyWith(
      result: currentResult.copyWith(products: localizedProducts),
    );
  }

  Future<List<ProductRecommendation>> _translateProducts(
    List<ProductRecommendation> products, {
    String? langCode,
  }) async {
    final effectiveLangCode = langCode ?? ref.read(localeProvider).languageCode;
    if (effectiveLangCode == 'en' || products.isEmpty) {
      return products;
    }

    // Batch translate all product names at once instead of looping
    final productNames = products.map((p) => p.productName).toList();
    final translatedNames = await TranslatorUtil.translateBatch(
      texts: productNames,
      langCode: effectiveLangCode,
    );

    return List.generate(
      products.length,
      (i) => ProductRecommendation(
        productName: i < translatedNames.length
            ? translatedNames[i]
            : products[i].productName,
        productImage: products[i].productImage,
        productUrl: products[i].productUrl,
      ),
    );
  }
}

final detectionProvider =
    NotifierProvider<DetectionNotifier, DetectionState>(DetectionNotifier.new);
