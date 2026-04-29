import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_models.dart';
import '../providers/auth_provider.dart';

class WeatherState {
  final WeatherModel? weather;
  final bool isLoading;
  final String? error;
  final String locationName;

  /// Timestamp of last successful fetch — used for stale-time guard.
  final DateTime? lastFetchedAt;

  const WeatherState({
    this.weather,
    this.isLoading = false,
    this.error,
    this.locationName = 'Your Location',
    this.lastFetchedAt,
  });

  WeatherState copyWith({
    WeatherModel? weather,
    bool? isLoading,
    String? error,
    String? locationName,
    DateTime? lastFetchedAt,
    bool clearError = false,
  }) =>
      WeatherState(
        weather: weather ?? this.weather,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        locationName: locationName ?? this.locationName,
        lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      );

  /// Returns true if the cached weather is still fresh (< 15 min old).
  bool get isFresh =>
      lastFetchedAt != null &&
      DateTime.now().difference(lastFetchedAt!) < const Duration(minutes: 15);
}

class WeatherNotifier extends Notifier<WeatherState> {
  @override
  WeatherState build() => const WeatherState();

  Future<void> fetchWeather({bool forceRefresh = false}) async {
    // ── Stale-time guard ──────────────────────────────────────────────────
    // Skip if we already have fresh data and no forced refresh is requested.
    if (!forceRefresh && state.isFresh && state.weather != null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        await _fetchForCoords(12.9716, 77.5946, 'Bengaluru');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );

      String cityName = 'Your Location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final village = p.subLocality?.trim();
          final city = p.locality?.trim();
          final subAdmin = p.subAdministrativeArea?.trim();
          final admin = p.administrativeArea?.trim();

          if (village != null &&
              village.isNotEmpty &&
              city != null &&
              city.isNotEmpty) {
            cityName = '$village, $city';
          } else if (city != null && city.isNotEmpty) {
            cityName = city;
          } else if (subAdmin != null && subAdmin.isNotEmpty) {
            cityName = subAdmin;
          } else if (admin != null && admin.isNotEmpty) {
            cityName = admin;
          }
        }
      } catch (e) {
        debugPrint('City name fetch error: $e');
      }

      await _fetchForCoords(position.latitude, position.longitude, cityName);
    } catch (e) {
      debugPrint('Location error: $e — falling back to Bengaluru');
      await _fetchForCoords(12.9716, 77.5946, 'Bengaluru');
    }
  }

  Future<void> _fetchForCoords(
      double lat, double lon, String locationName) async {
    final api = ref.read(apiServiceProvider);
    final res = await api.getWeather(latitude: lat, longitude: lon);

    if (res.isSuccess && res.data != null) {
      state = state.copyWith(
        weather: res.data,
        isLoading: false,
        locationName: locationName,
        lastFetchedAt: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: res.error ?? 'Weather unavailable',
      );
    }
  }
}

final weatherProvider =
    NotifierProvider<WeatherNotifier, WeatherState>(WeatherNotifier.new);
