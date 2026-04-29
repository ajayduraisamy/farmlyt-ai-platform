import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_models.dart';
import '../providers/crop_tips_provider.dart';
import '../utils/app_constants.dart';

// ---------------------------------------------------------------------------
// OTP result returned from register / login before OTP verification
// ---------------------------------------------------------------------------
class OtpResult {
  final String userId;
  final String? otp;
  final String? displayName;
  final String? phone;

  const OtpResult({
    required this.userId,
    this.otp,
    this.displayName,
    this.phone,
  });
}

// ---------------------------------------------------------------------------
// Simple in-memory cache entry with TTL
// ---------------------------------------------------------------------------
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry(this.data, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

// ---------------------------------------------------------------------------
// ApiService
// ---------------------------------------------------------------------------
class ApiService {
  late final Dio _authDio;
  late final Dio _prodDio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── In-memory response cache (keyed by endpoint string) ──────────────────
  final Map<String, _CacheEntry<dynamic>> _cache = {};

  // Cache TTLs — tune these to match your backend data freshness needs
  static const Duration _tipsTtl = Duration(hours: 2);
  static const Duration _categoriesTtl = Duration(hours: 1);
  static const Duration _weatherTtl = Duration(minutes: 15);
  static const Duration _agriTitlesTtl = Duration(hours: 2);
  static const Duration _cropSubTtl = Duration(hours: 2);
  static const Duration _productsTtl = Duration(hours: 1);
  static const Duration _cropTipsTtl = Duration(hours: 2);

  // Maximum compressed image dimension (px) before upload
  static const int _maxImageDimension = 768;
  // JPEG quality for compression (0-100) - lower = faster upload + smaller file
  static const int _imageQuality = 70;

  ApiService() {
    final ct = const Duration(milliseconds: AppConstants.connectTimeout);
    final rt = const Duration(milliseconds: AppConstants.receiveTimeout);

    // ── Auth Dio (no token, no retry needed — fast auth calls) ─────────────
    _authDio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: ct,
      receiveTimeout: rt,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    _configureKeepAlive(_authDio);

    // ── Production Dio (token, retry, keep-alive) ───────────────────────────
    _prodDio = Dio(BaseOptions(
      baseUrl: AppConstants.productionBaseUrl,
      connectTimeout: ct,
      receiveTimeout: rt,
      headers: {'Accept': 'application/json'},
    ));
    _configureKeepAlive(_prodDio);

    // Attach auth token to every prod request
    _prodDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.keyToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    // Retry interceptor — retries once on connection/timeout errors only
    _prodDio.interceptors.add(_RetryInterceptor(_prodDio, maxRetries: 1));
  }

  /// Enable HTTP/1.1 keep-alive connection reuse to avoid TCP handshake on
  /// every request.
  void _configureKeepAlive(Dio dio) {
    if (!kIsWeb) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 30);
        return client;
      };
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Cache helpers
  // ══════════════════════════════════════════════════════════════════════════

  T? _getCache<T>(String key) {
    final entry = _cache[key];
    if (entry != null && entry.isValid) return entry.data as T;
    _cache.remove(key); // Evict stale entry
    return null;
  }

  void _setCache(String key, dynamic data, Duration ttl) {
    _cache[key] = _CacheEntry(data, ttl);
  }

  /// Invalidate a specific cache key (call after mutations).
  void invalidateCache(String key) => _cache.remove(key);

  /// Clear all cached responses (e.g., on logout).
  void clearCache() => _cache.clear();

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH — Phone / Firebase
  // ══════════════════════════════════════════════════════════════════════════

  Future<ApiResponse<UserModel>> register({
    required String name,
    required String phone,
    String email = '',
    String password = '',
  }) async {
    try {
      final res = await _authDio.post(AppConstants.registerEndpoint, data: {
        'name': name,
        'email': email.isNotEmpty ? email : '$phone@farmlyt.ai',
        'phone': phone,
        'password': password.isNotEmpty ? password : phone,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final user =
            UserModel.fromJson(Map<String, dynamic>.from(res.data as Map));
        await _storage.write(key: AppConstants.keyToken, value: user.token);
        return ApiResponse.success(user);
      }
      return ApiResponse.error('Registration failed');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Unexpected error');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH — Email OTP
  // ══════════════════════════════════════════════════════════════════════════

  Future<ApiResponse<OtpResult>> emailRegister({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'email': email,
        'password': 'otp_${email.trim().toLowerCase()}',
      };
      if (phone.trim().isNotEmpty) payload['phone'] = phone.trim();

      final res = await _prodDio.post('/auth/register', data: payload);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = Map<String, dynamic>.from((res.data as Map?) ?? const {});
        final userPayload = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : data;

        return ApiResponse.success(OtpResult(
          userId: data['user_id']?.toString() ??
              userPayload['id']?.toString() ??
              '',
          otp: data['otp']?.toString(),
          displayName: _extractUserName(userPayload, data),
          phone: _extractUserPhone(userPayload, data),
        ));
      }
      return ApiResponse.error('Register failed');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Unexpected error');
    }
  }

  Future<ApiResponse<OtpResult>> emailLogin({required String email}) async {
    try {
      final res = await _prodDio.post('/auth/login', data: {'email': email});
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(res.data as Map);
        final userPayload = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : data;
        return ApiResponse.success(OtpResult(
          userId: data['user_id']?.toString() ?? '',
          otp: data['otp']?.toString(),
          displayName: _extractUserName(userPayload, data),
          phone: _extractUserPhone(userPayload, data),
        ));
      }
      return ApiResponse.error(_extractMsg(res.data) ?? 'Login failed');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Unexpected error');
    }
  }

  Future<ApiResponse<UserModel>> verifyEmailOtp({
    required String userId,
    required String otp,
    String email = '',
  }) async {
    try {
      final res = await _prodDio
          .post('/auth/verify-otp', data: {'user_id': userId, 'otp': otp});
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(res.data as Map);
        final userPayload = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : data;

        final uid = userPayload['id']?.toString() ??
            data['user_id']?.toString() ??
            userId;
        final credits = _asInt(userPayload['credits'] ?? data['credits'] ?? 0);
        final isNewUser = data['new_user'] == true;

        // Prefer response email; fall back to caller-supplied email so it
        // is never silently lost.
        final resolvedEmail = (userPayload['email']?.toString() ??
                    data['email']?.toString() ??
                    '')
                .trim()
                .isNotEmpty
            ? (userPayload['email']?.toString() ??
                data['email']?.toString() ??
                '')
            : email;

        final finalUser = UserModel(
          id: uid,
          name: _extractUserName(userPayload, data),
          phone: _extractUserPhone(userPayload, data),
          email: resolvedEmail,
          token: data['token']?.toString() ??
              data['access_token']?.toString() ??
              uid,
          credits: credits > 0
              ? credits
              : (isNewUser ? AppConstants.initialCredits : 0),
        );
        await _storage.write(
            key: AppConstants.keyToken, value: finalUser.token);
        return ApiResponse.success(finalUser);
      }
      return ApiResponse.error(
          _extractMsg(res.data) ?? 'OTP verification failed');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Unexpected error');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WALLET
  // ══════════════════════════════════════════════════════════════════════════

  Future<ApiResponse<int>> getWallet({required String userId}) async {
    try {
      final res = await _prodDio.get('/user/wallet/$userId');
      if (res.statusCode == 200) {
        final data = res.data;
        int credits = 0;
        if (data is Map) {
          credits = _asInt(data['coins'] ?? data['credits'] ?? data['balance']);
        } else if (data is int) {
          credits = data;
        }
        return ApiResponse.success(credits);
      }
      return ApiResponse.error('Failed to fetch wallet');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not load wallet');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAYMENT — Razorpay
  // ══════════════════════════════════════════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required String userId,
    required int amountInr,
  }) async {
    try {
      final res = await _prodDio.post(
        AppConstants.createOrderEndpoint,
        data: {'user_id': userId, 'amount': amountInr},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return ApiResponse.success(Map<String, dynamic>.from(res.data as Map));
      }
      return ApiResponse.error(
          _extractMsg(res.data) ?? 'Order creation failed');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not create order');
    }
  }

  Future<ApiResponse<int>> verifyPayment({
    required String userId,
    required String paymentId,
    required String orderId,
    required String signature,
    required int amountInr,
  }) async {
    try {
      final res = await _prodDio.post(
        AppConstants.verifyPaymentEndpoint,
        data: {
          'user_id': userId,
          'payment_id': paymentId,
          'order_id': orderId,
          'signature': signature,
          'amount': amountInr,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        return ApiResponse.success(
            _asInt(data['coins_added'] ?? data['credits'] ?? amountInr));
      }
      return ApiResponse.error(
          _extractMsg(res.data) ?? 'Payment verification failed');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Payment verification failed');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DETECTION  (with image compression + overall timeout)
  // ══════════════════════════════════════════════════════════════════════════

  Future<ApiResponse<DetectionResult>> detectDisease({
    required File imageFile,
    required String category,
    required String cropKey,
    required String userId,
  }) async {
    final startTime = DateTime.now();

    // ── Step 1: Compress image on a background isolate ─────────────────────
    final File uploadFile = await _compressImage(imageFile);
    final compressTime = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('[API] Image compression took ${compressTime}ms');

    final endpoints = AppConstants.getDetectionEndpoints(category, cropKey);
    final fileName = uploadFile.path.split(Platform.pathSeparator).last;
    String? lastError;
    String? modelError;

    for (final endpoint in endpoints) {
      try {
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            uploadFile.path,
            filename: fileName.isEmpty ? 'crop_image.jpg' : fileName,
          ),
          'user_id': userId,
        });

        final res = await _prodDio
            .post(
              endpoint,
              data: formData,
              options: Options(
                contentType: 'multipart/form-data',
                receiveTimeout: const Duration(seconds: 90),
              ),
            )
            .timeout(const Duration(seconds: 100));

        if (res.statusCode == 200 && res.data is Map) {
          final result = DetectionResult.fromApiResponse(
            Map<String, dynamic>.from(res.data as Map),
          );
          final totalTime = DateTime.now().difference(startTime).inMilliseconds;
          debugPrint(
              '[API] Full detection took ${totalTime}ms (upload + inference)');
          return ApiResponse.success(result);
        }

        lastError =
            _extractMsg(res.data) ?? 'Detection failed. Please try again.';
      } on TimeoutException {
        return ApiResponse.error(
            'Detection timed out. Check your connection and try again.');
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        final error = _dioErr(e);
        lastError = error;

        // 📉 Braces added to fix the info warning
        if (code == 404 || code == 405) {
          lastError = 'Detection model endpoint not found for this crop.';
          continue;
        }

        if (error.toLowerCase().contains('invalid crop mapping') &&
            endpoint != endpoints.last) {
          modelError = error;
          continue;
        }

        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          return ApiResponse.error('No internet connection.');
        }

        // 📉 Braces added to fix the info warning
        final loweredError = error.toLowerCase();
        if ((loweredError.contains('route not found') ||
                loweredError.contains('endpoint not found')) &&
            endpoint != endpoints.last) {
          continue;
        }

        return ApiResponse.error(error);
      } catch (_) {
        lastError = 'Analysis failed. Please try again.';
      }
    }

    return ApiResponse.error(
        modelError ?? lastError ?? 'Detection failed. Please try again.');
  }

  // ── Image compression helper ───────────────────────────────────────────
  /// Compresses [imageFile] to ≤ [_maxImageDimension]px on the longest side
  /// at [_imageQuality]% JPEG quality.  Falls back to the original file if
  /// compression fails so detection is never blocked.
  Future<File> _compressImage(File imageFile) async {
    try {
      final targetPath =
          '${imageFile.parent.path}/compressed_${imageFile.path.split(Platform.pathSeparator).last}';

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: _imageQuality,
        minWidth: _maxImageDimension,
        minHeight: _maxImageDimension,
        keepExif: false,
      );

      if (result != null) {
        final compressed = File(result.path);
        debugPrint(
          '[ApiService] Image compressed: '
          '${imageFile.lengthSync()} → ${compressed.lengthSync()} bytes',
        );
        return compressed;
      }
    } catch (e) {
      debugPrint('[ApiService] Image compression failed: $e — using original');
    }
    return imageFile;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FARMING TIPS & CATEGORIES  (with caching)
  // ══════════════════════════════════════════════════════════════════════════

  Future<ApiResponse<List<AgriTitle>>> getAgriTitles() async {
    const cacheKey = 'agri_titles';
    final cached = _getCache<List<AgriTitle>>(cacheKey);
    if (cached != null) return ApiResponse.success(cached);

    try {
      final res = await _prodDio.get(AppConstants.getAgriTitlesEndpoint);
      if (res.statusCode == 200 && res.data is List) {
        final titles = (res.data as List)
            .whereType<Map>()
            .map((item) => AgriTitle.fromJson(Map<String, dynamic>.from(item)))
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        _setCache(cacheKey, titles, _agriTitlesTtl);
        return ApiResponse.success(titles);
      }
      return ApiResponse.error('Failed to load agriculture titles');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not load agriculture titles');
    }
  }

  Future<ApiResponse<List<FarmingTip>>> getFarmingTips() async {
    const cacheKey = 'farming_tips';
    final cached = _getCache<List<FarmingTip>>(cacheKey);
    if (cached != null) return ApiResponse.success(cached);

    try {
      final res = await _prodDio.get(AppConstants.getFarmingTipsEndpoint);
      if (res.statusCode == 200 && res.data is List) {
        final tips = (res.data as List)
            .map((j) => FarmingTip.fromJson(j as Map<String, dynamic>))
            .toList();
        _setCache(cacheKey, tips, _tipsTtl);
        return ApiResponse.success(tips);
      }
      return ApiResponse.error('Failed to load tips');
    } catch (_) {
      return ApiResponse.error('Could not load tips');
    }
  }

  /// Fetches categories and sub-categories in PARALLEL, then merges them.
  /// Previously these were serial (sub called inside categories).
  Future<ApiResponse<List<DetectionCategory>>> getCategories({
    int? agriId,
  }) async {
    final cacheKey = 'categories_${agriId ?? 0}';
    final cached = _getCache<List<DetectionCategory>>(cacheKey);
    if (cached != null) return ApiResponse.success(cached);

    try {
      // ── Parallel fetch ───────────────────────────────────────────────────
      final results = await Future.wait([
        _prodDio.get(AppConstants.getCropsEndpoint),
        _prodDio.get(AppConstants.getCropSubEndpoint),
      ]);

      final cropsRes = results[0];
      final subRes = results[1];

      if (cropsRes.statusCode != 200 || cropsRes.data is! List) {
        return ApiResponse.error('Failed to load categories');
      }

      // Parse on a background isolate to avoid jank on large payloads
      final rawCategories = await compute(
        _parseRawCategories,
        cropsRes.data as List,
      );

      final groupedById = <int, List<CropOption>>{};
      final groupedByTitle = <String, List<CropOption>>{};

      if (subRes.statusCode == 200 && subRes.data is List) {
        final cropOptions = await compute(
          _parseCropOptions,
          subRes.data as List,
        );
        for (final option in cropOptions) {
          groupedById
              .putIfAbsent(option.categoryId, () => <CropOption>[])
              .add(option);
          final normalizedTitle = _normalizeTitleKey(option.categoryTitle);
          groupedByTitle
              .putIfAbsent(normalizedTitle, () => <CropOption>[])
              .add(option);
        }
      }

      final categories = rawCategories.map((item) {
        final category = DetectionCategory.fromApiJson(item);
        final titleKey = _normalizeTitleKey(category.title);
        final options = groupedById[category.backendId] ??
            groupedByTitle[titleKey] ??
            const <CropOption>[];
        return category.withCropOptions(options);
      }).where((category) {
        if (agriId == null || agriId <= 0) {
          return true;
        }
        return category.agriId == agriId;
      }).toList();

      _setCache(cacheKey, categories, _categoriesTtl);
      return ApiResponse.success(categories);
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not fetch categories');
    }
  }

  Future<ApiResponse<List<CropOption>>> getCropSubcategories() async {
    const cacheKey = 'crop_sub';
    final cached = _getCache<List<CropOption>>(cacheKey);
    if (cached != null) return ApiResponse.success(cached);

    try {
      final res = await _prodDio.get(AppConstants.getCropSubEndpoint);
      if (res.statusCode == 200 && res.data is List) {
        final cropOptions = (res.data as List)
            .whereType<Map>()
            .map((item) => CropOption.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _setCache(cacheKey, cropOptions, _cropSubTtl);
        return ApiResponse.success(cropOptions);
      }
      return ApiResponse.error('Failed to load crop options');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not fetch crop options');
    }
  }

  Future<ApiResponse<List<PredictionHistoryItem>>> getPredictions() async {
    try {
      final res = await _prodDio.get(AppConstants.getLeafPredictionsEndpoint);
      if (res.statusCode == 200 && res.data is List) {
        final predictions = (res.data as List)
            .whereType<Map>()
            .map((item) =>
                PredictionHistoryItem.fromJson(Map<String, dynamic>.from(item)))
            .toList()
          ..sort((a, b) {
            final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return at != bt ? bt.compareTo(at) : b.id.compareTo(a.id);
          });
        return ApiResponse.success(predictions);
      }
      return ApiResponse.error('Failed to load predictions');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not fetch predictions');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CROP TIPS  (with caching + dedicated reusable Dio)
  // ══════════════════════════════════════════════════════════════════════════

  // Reuse a single Dio for the HF space endpoint instead of creating new
  // instances on every call (avoids TCP handshake overhead).
  static final Dio _hfDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json'},
  ));

  Future<ApiResponse<List<CropTip>>> getCropTips() async {
    const cacheKey = 'crop_tips';
    final cached = _getCache<List<CropTip>>(cacheKey);
    if (cached != null) return ApiResponse.success(cached);

    try {
      final res = await _hfDio.get(
        'https://aislynajay-product-development.hf.space/get_tips',
      );
      if (res.statusCode == 200 && res.data is List) {
        final tips = (res.data as List)
            .whereType<Map>()
            .map((item) => CropTip.fromJson(Map<String, dynamic>.from(item)))
            .where((tip) => tip.cropSubName.isNotEmpty)
            .toList();
        _setCache(cacheKey, tips, _cropTipsTtl);
        return ApiResponse.success(tips);
      }
      return ApiResponse.error('Failed to load crop tips');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not fetch crop tips');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRODUCTS  (with caching)
  // ══════════════════════════════════════════════════════════════════════════

  Future<ApiResponse<List<CropProduct>>> getCropWithProducts() async {
    const cacheKey = 'crop_products';
    final cached = _getCache<List<CropProduct>>(cacheKey);
    if (cached != null) return ApiResponse.success(cached);

    try {
      final res = await _prodDio.get('/get_crop_with_products');
      if (res.statusCode == 200 && res.data is List) {
        final products = (res.data as List)
            .whereType<Map>()
            .map(
                (item) => CropProduct.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _setCache(cacheKey, products, _productsTtl);
        return ApiResponse.success(products);
      }
      return ApiResponse.error('Failed to load products');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not fetch products');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE UPDATE
  // ══════════════════════════════════════════════════════════════════════════

  Future<ApiResponse<UserModel>> updateProfile({
    required String userId,
    required String name,
    String email = '',
    String phone = '',
  }) async {
    try {
      final payload = <String, dynamic>{'user_id': userId, 'name': name};
      if (email.trim().isNotEmpty) payload['email'] = email.trim();
      if (phone.trim().isNotEmpty) payload['phone'] = phone.trim();

      final res = await _prodDio.post(
        AppConstants.updateProfileEndpoint,
        data: payload,
      );

      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        final userPayload = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : data;

        return ApiResponse.success(UserModel(
          id: userPayload['id']?.toString() ??
              data['user_id']?.toString() ??
              userId,
          name: userPayload['name']?.toString() ?? name,
          phone: userPayload['phone']?.toString() ?? phone,
          email: userPayload['email']?.toString() ?? email,
          token: userPayload['token']?.toString() ??
              data['token']?.toString() ??
              '',
          credits: _asInt(userPayload['credits'] ?? data['credits'] ?? 0),
          profileImagePath: userPayload['profile_image_path']?.toString() ??
              userPayload['profileImagePath']?.toString(),
        ));
      }
      return ApiResponse.error(
          _extractMsg(res.data) ?? 'Profile update failed');
    } on DioException catch (e) {
      return ApiResponse.error(_dioErr(e));
    } catch (_) {
      return ApiResponse.error('Could not update profile');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WEATHER  (with caching + reusable Dio)
  // ══════════════════════════════════════════════════════════════════════════

  static final Dio _weatherDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  Future<ApiResponse<WeatherModel>> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Round to 2 decimal places so nearby positions share cache entries
    final lat = double.parse(latitude.toStringAsFixed(2));
    final lon = double.parse(longitude.toStringAsFixed(2));
    final cacheKey = 'weather_${lat}_$lon';

    final cached = _getCache<WeatherModel>(cacheKey);
    if (cached != null) return ApiResponse.success(cached);

    try {
      final res = await _weatherDio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current_weather': true,
          'daily': 'temperature_2m_max,weathercode',
          'hourly':
              'apparent_temperature,temperature_2m,relative_humidity_2m,precipitation_probability,uv_index,soil_temperature_0cm,soil_moisture_0_to_1cm',
          'timezone': 'auto',
          'forecast_days': 7,
        },
      );
      if (res.statusCode == 200) {
        final model =
            WeatherModel.fromJson(Map<String, dynamic>.from(res.data as Map));
        _setCache(cacheKey, model, _weatherTtl);
        return ApiResponse.success(model);
      }
      return ApiResponse.error('Failed to fetch weather');
    } catch (_) {
      return ApiResponse.error('Weather unavailable');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ISOLATE-FRIENDLY JSON PARSERS (called via compute())
  // ══════════════════════════════════════════════════════════════════════════

  static List<Map<String, dynamic>> _parseRawCategories(List raw) {
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<CropOption> _parseCropOptions(List raw) {
    return raw
        .whereType<Map>()
        .map((item) => CropOption.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String? _extractMsg(dynamic data) {
    if (data is Map) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          data['detail']?.toString();
    }
    return null;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _normalizeTitleKey(String rawTitle) =>
      rawTitle.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _extractUserName(
    Map<String, dynamic> primary, [
    Map<String, dynamic>? fallback,
  ]) {
    for (final source in [primary, if (fallback != null) fallback]) {
      final name = source['name']?.toString().trim() ??
          source['full_name']?.toString().trim() ??
          source['fullName']?.toString().trim() ??
          source['username']?.toString().trim() ??
          source['user_name']?.toString().trim() ??
          source['display_name']?.toString().trim() ??
          source['displayName']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return '';
  }

  String _extractUserPhone(
    Map<String, dynamic> primary, [
    Map<String, dynamic>? fallback,
  ]) {
    for (final source in [primary, if (fallback != null) fallback]) {
      final phone = source['phone']?.toString().trim() ??
          source['mobile']?.toString().trim() ??
          source['phone_number']?.toString().trim() ??
          source['phoneNumber']?.toString().trim();
      if (phone != null && phone.isNotEmpty) return phone;
    }
    return '';
  }

  String _dioErr(DioException e) {
    final backendMsg = _extractMsg(e.response?.data);
    if (backendMsg != null) return backendMsg;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Check your internet.';
      case DioExceptionType.receiveTimeout:
        return 'Server not responding. Try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'Invalid credentials. Please try again.';
        if (code == 403) {
          return 'Account not verified. Check your email for OTP.';
        }
        if (code == 404) return 'Account not found. Please register first.';
        if (code == 429) return 'Too many requests. Wait and try again.';
        if (code == 500) return 'Server error. Try again later.';
        return 'Request failed ($code)';
      default:
        return 'Something went wrong. Try again.';
    }
  }
}

// ---------------------------------------------------------------------------
// Retry interceptor — transparent single retry on transient failures
// ---------------------------------------------------------------------------
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  _RetryInterceptor(this.dio, {this.maxRetries = 1});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['retry_count'] as int?) ?? 0;

    final isRetryable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    // Do not retry file uploads — they are expensive and may have side effects
    final isUpload = err.requestOptions.data is FormData;

    if (isRetryable && !isUpload && retryCount < maxRetries) {
      extra['retry_count'] = retryCount + 1;
      await Future<void>.delayed(
          Duration(milliseconds: 300 * (retryCount + 1)));
      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // Fall through to original error
      }
    }
    handler.next(err);
  }
}

// ---------------------------------------------------------------------------
// Generic response wrapper
// ---------------------------------------------------------------------------
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T data) =>
      ApiResponse._(data: data, isSuccess: true);
  factory ApiResponse.error(String error) =>
      ApiResponse._(error: error, isSuccess: false);
}
