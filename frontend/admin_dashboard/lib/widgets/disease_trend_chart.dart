import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_model.dart';

class DiseaseTrendChart extends StatelessWidget {
  final List<TrendPoint> data;

  const DiseaseTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((p) => p.total == 0)) {
      return const _EmptyChart(message: 'No scan data available');
    }

    final maxY = data
            .map((p) => p.total)
            .fold(0, (a, b) => a > b ? a : b)
            .toDouble() +
        2;

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.total.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxY / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFEEF0F4), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final date = DateTime.tryParse(data[idx].date);
                if (date == null) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('MMM d').format(date),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFDDE1E7)),
            left: BorderSide(color: Color(0xFFDDE1E7)),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: kDeepGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: kDeepGreen,
                strokeColor: Colors.white,
                strokeWidth: 1.5,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kDeepGreen.withOpacity(0.18),
                  kDeepGreen.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kDeepGreen,
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt();
              final date = idx < data.length
                  ? DateTime.tryParse(data[idx].date)
                  : null;
              return LineTooltipItem(
                '${date != null ? DateFormat('MMM d').format(date) : ''}\n${s.y.toInt()} scans',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlyPoint> data;

  const MonthlyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No monthly data available');
    }

    final maxY = data
            .map((p) => p.total)
            .fold(0, (a, b) => a > b ? a : b)
            .toDouble() +
        4;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => kDeepGreen,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${data[group.x].label}\n${rod.toY.toInt()} scans',
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data[i].label.split(' ').first,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFEEF0F4), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFDDE1E7)),
            left: BorderSide(color: Color(0xFFDDE1E7)),
          ),
        ),
        barGroups: data.asMap().entries.map((e) {
          final idx = e.key;
          final point = e.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: point.total.toDouble(),
                width: 28,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                rodStackItems: [
                  BarChartRodStackItem(
                      0,
                      point.healthy.toDouble(),
                      kLightGreen.withOpacity(0.85)),
                  BarChartRodStackItem(
                      point.healthy.toDouble(),
                      point.total.toDouble(),
                      kErrorRed.withOpacity(0.85)),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class DiseasePieChart extends StatefulWidget {
  final List<DiseaseRank> data;
  const DiseasePieChart({super.key, required this.data});
  @override
  State<DiseasePieChart> createState() => _DiseasePieChartState();
}

class _DiseasePieChartState extends State<DiseasePieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const _EmptyChart(message: 'No disease data');
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touched = -1;
                    } else {
                      _touched = response
                          .touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              sections: widget.data.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;
                final isTouched = idx == _touched;
                Color color;
                try {
                  final hex = item.colorHex.replaceAll('#', '');
                  color = Color(int.parse('FF$hex', radix: 16));
                } catch (_) {
                  color = Colors.grey;
                }
                return PieChartSectionData(
                  value: item.percentage,
                  color: color,
                  radius: isTouched ? 72 : 60,
                  title: '${item.percentage.toStringAsFixed(0)}%',
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: widget.data.map((item) {
            Color color;
            try {
              final hex = item.colorHex.replaceAll('#', '');
              color = Color(int.parse('FF$hex', radix: 16));
            } catch (_) {
              color = Colors.grey;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(item.disease,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text('(${item.count})',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
