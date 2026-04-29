import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../providers/weather_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/app_models.dart';
import 'weather_graph_widget.dart';

class WeatherCardWidget extends ConsumerWidget {
  const WeatherCardWidget({super.key});

  List<Color> _getGradientColors(int code) {
    if (code == 0) return [const Color(0xFF0288D1), const Color(0xFF26C6DA)];
    if (code <= 3) return [const Color(0xFF0277BD), const Color(0xFF29B6F6)];
    if (code <= 49) return [const Color(0xFF455A64), const Color(0xFF90A4AE)];
    return [const Color(0xFF37474F), const Color(0xFF546E7A)];
  }

  String _getWeatherLottie(int code) {
    if (code == 0) return 'assets/lottie/sun.json';
    if (code <= 3) return 'assets/lottie/cloud.json';
    if (code <= 49) return 'assets/lottie/fog.json';
    if (code <= 69) return 'assets/lottie/rain.json';
    return 'assets/lottie/storm.json';
  }

  String _get3DWeatherIcon(int code) {
    if (code == 0) return 'assets/weather/sun_3d.png';
    if (code <= 3) return 'assets/weather/cloud_3d.png';
    if (code <= 49) return 'assets/weather/fog_3d.png';
    if (code <= 69) return 'assets/weather/rain_3d.png';
    return 'assets/weather/storm_3d.png';
  }

  // 🛡️ UV Level Logic
  String _getUVLevel(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Mod';
    if (uv <= 7) return 'High';
    return 'Extreme';
  }

  Color _getUVColor(double uv) {
    if (uv <= 2) return Colors.greenAccent;
    if (uv <= 5) return Colors.yellowAccent;
    if (uv <= 7) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Map<String, dynamic> _getGraphData(WeatherModel w) {
    List<double> filteredTemps = [];
    List<String> filteredTimes = [];
    final now = DateTime.now();
    int startIndex = 0;
    for (int i = 0; i < w.hourlyTime.length; i++) {
      final parsedTime = DateTime.parse(w.hourlyTime[i]);
      if (parsedTime.isAfter(now) || parsedTime.hour == now.hour) {
        startIndex = i;
        break;
      }
    }
    for (int i = startIndex;
        i < w.hourlyTime.length && filteredTemps.length < 8;
        i += 3) {
      filteredTemps.add(w.hourlyTemperature[i]);
      final parsedTime = DateTime.parse(w.hourlyTime[i]);
      int hour = parsedTime.hour;
      String ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      filteredTimes.add('$hour $ampm');
    }
    return {'temps': filteredTemps, 'times': filteredTimes};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherProvider);
    final l = AppLocalizations.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 380;

    if (weatherState.isLoading) return _buildShimmer();
    if (weatherState.weather == null) return _buildError(ref, l);

    final w = weatherState.weather!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(w.weatherCode),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(weatherState.locationName,
                        maxLines: 1,
                        style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 8 : 9,
                            fontWeight: FontWeight.bold)),
                    Text('${w.temperature.toStringAsFixed(1)}°C',
                        style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.w900,
                            height: 1)),
                    Text(_weatherDescription(w.weatherCode, l),
                        style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 9 : 10)),
                  ],
                ),
              ),
              Lottie.asset(
                _getWeatherLottie(w.weatherCode),
                width: isSmallScreen ? 38 : 45,
                height: isSmallScreen ? 38 : 45,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset(_get3DWeatherIcon(w.weatherCode), width: 35),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // ── Row 1: Basic Weather Stats ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat(
                  '💨', '${w.windspeed.toInt()}km/h', 'Wind', isSmallScreen),
              _miniStat('🌡️', '${w.apparentTemperature.toInt()}°', 'Feels',
                  isSmallScreen),
              _miniStat(
                  '💧', '${w.hourlyHumidity[0]}%', 'Humid', isSmallScreen),
              _miniStat(
                  '🌧️', '${w.hourlyRainChance[0]}%', 'Rain', isSmallScreen),
            ],
          ),
          const SizedBox(height: 5),
          // ── Row 2: Health Indicators (UV & Soil) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _healthStat(
                  '☀️',
                  'UV',
                  '${w.uvIndex.toStringAsFixed(1)} (${_getUVLevel(w.uvIndex)})',
                  _getUVColor(w.uvIndex),
                  isSmallScreen),
              _healthStat('🪴', 'Soil T', '${w.soilTemperature.toInt()}°C',
                  Colors.white, isSmallScreen),
              _healthStat('💧', 'Soil M', '${(w.soilMoisture * 100).toInt()}%',
                  Colors.white, isSmallScreen),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: isSmallScreen ? 50 : 55,
            child: Builder(builder: (context) {
              final graphData = _getGraphData(w);
              return PremiumWeatherGraph(
                hourlyTemps: graphData['temps'] as List<double>,
                hourlyTimes: graphData['times'] as List<String>,
              );
            }),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: isSmallScreen ? 45 : 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: w.dailyTime.length - 1,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, i) {
                final index = i + 1;
                return _compactForecast(
                    w.dailyTime[index],
                    w.dailyMaxTemp[index],
                    w.dailyWeatherCode[index],
                    isSmallScreen);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String val, String label, bool isSmall) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: isSmall ? 10 : 11)),
        Text(val,
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: isSmall ? 7 : 8,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.nunito(
                color: Colors.white60, fontSize: isSmall ? 6 : 7)),
      ],
    );
  }

  // ── NEW: Compact Health Stat Widget ──
  Widget _healthStat(
      String icon, String label, String val, Color valColor, bool isSmall) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: isSmall ? 9 : 10)),
          const SizedBox(width: 3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      color: Colors.white54, fontSize: isSmall ? 6 : 6.5)),
              Text(val,
                  style: GoogleFonts.nunito(
                      color: valColor,
                      fontSize: isSmall ? 7 : 8,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactForecast(String date, double temp, int code, bool isSmall) {
    final day = DateTime.parse(date);
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      width: isSmall ? 38 : 42,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(dayNames[day.weekday - 1],
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: isSmall ? 6 : 7,
                  fontWeight: FontWeight.bold)),
          Text(_miniEmoji(code), style: TextStyle(fontSize: isSmall ? 9 : 11)),
          Text('${temp.toInt()}°',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 7 : 8,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  String _miniEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    return '🌧️';
  }

  String _weatherDescription(int code, AppLocalizations l) {
    if (code == 0) return l.t('weather_clear_sky');
    if (code <= 3) return l.t('weather_partly_cloudy');
    return l.t('weather_rain');
  }

  Widget _buildShimmer() => Container(
      margin: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
          color: Colors.grey[300], borderRadius: BorderRadius.circular(22)));

  Widget _buildError(WidgetRef ref, AppLocalizations l) => Center(
      child: Text('Error Loading Weather',
          style: TextStyle(color: Colors.white70, fontSize: 10)));
}
