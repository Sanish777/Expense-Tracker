import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class SpendingChart extends StatefulWidget {
  final Map<String, double> breakdown;

  const SpendingChart({super.key, required this.breakdown});

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.breakdown.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 56, color: AppTheme.primary.withOpacity(0.3)),
              const SizedBox(height: 12),
              const Text('No data yet',
                  style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    final entries = widget.breakdown.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          // Pie chart
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex =
                          response?.touchedSection?.touchedSectionIndex ?? -1;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                sections: List.generate(entries.length, (i) {
                  final isTouched = i == _touchedIndex;
                  final color =
                      Color(AnalyticsService.categoryColor(entries[i].key));
                  return PieChartSectionData(
                    color: color,
                    value: entries[i].value,
                    title: isTouched
                        ? '${((entries[i].value / total) * 100).toStringAsFixed(0)}%'
                        : '',
                    radius: isTouched ? 58 : 50,
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),

          // Legend
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((entry) {
              final color =
                  Color(AnalyticsService.categoryColor(entry.key));
              final pct = ((entry.value / total) * 100).toStringAsFixed(0);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key[0].toUpperCase()}${entry.key.substring(1)} $pct%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
