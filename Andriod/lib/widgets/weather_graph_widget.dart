import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumWeatherGraph extends StatelessWidget {
  final List<double> hourlyTemps;
  final List<String> hourlyTimes;

  const PremiumWeatherGraph({
    super.key,
    required this.hourlyTemps,
    required this.hourlyTimes,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyTemps.isEmpty || hourlyTemps.length != hourlyTimes.length) {
      return const SizedBox.shrink();
    }

    final spots = List.generate(
      hourlyTemps.length,
      (index) => FlSpot(index.toDouble(), hourlyTemps[index]),
    );

    final minTemp = hourlyTemps.reduce((a, b) => a < b ? a : b);
    final maxTemp = hourlyTemps.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 70, // 📉 Vertical space innum tighten panniyachu
      padding: const EdgeInsets.only(top: 10, bottom: 0),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              // 📉 tooltipRoundedRadius error-ah fix panna ithai remove panniyachu
              // Latest fl_chart-la getTooltipColor use pannale radius default-ah set aagidum
              getTooltipColor: (touchedSpot) => Colors.white,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.y.toStringAsFixed(1)}°C',
                    GoogleFonts.nunito(
                      color: const Color(0xFF0277BD),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: 0,
                color: Colors.white.withAlpha((0.4 * 255).toInt()),
                strokeWidth: 1.2,
                dashArray: [4, 4],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800),
                  labelResolver: (line) => 'Now',
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < hourlyTimes.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        hourlyTimes[index],
                        style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (hourlyTemps.length - 1).toDouble(),
          minY: minTemp - 2,
          maxY: maxTemp + 2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFFFD54F),
              barWidth: 2.2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true), // Simplified dots
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD54F).withAlpha((0.3 * 255).toInt()),
                    const Color(0xFFFFD54F).withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
