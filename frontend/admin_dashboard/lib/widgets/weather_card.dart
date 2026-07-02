import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/weather_model.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback? onRefresh;

  const WeatherCard({super.key, required this.weather, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.wb_cloudy_outlined,
                    color: kDeepGreen, size: 18),
                const SizedBox(width: 8),
                const Text('Current Weather',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: kDeepGreen)),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: onRefresh,
                    tooltip: 'Refresh weather',
                    color: Colors.grey,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Temperature + condition
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(weather.icon, size: 52, color: weather.iconColor),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${weather.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: kDeepGreen,
                            height: 1.0)),
                    Text(weather.condition,
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black54)),
                    Text(weather.location,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _WeatherStat(
                    icon: Icons.water_drop_outlined,
                    value: '${weather.humidity}%',
                    label: 'Humidity',
                    color: const Color(0xFF1976D2)),
                _WeatherStat(
                    icon: Icons.umbrella_outlined,
                    value: '${weather.precipitationProbability}%',
                    label: 'Rain',
                    color: const Color(0xFF0288D1)),
                _WeatherStat(
                    icon: Icons.air_rounded,
                    value: '${weather.windSpeed} km/h',
                    label: 'Wind',
                    color: const Color(0xFF546E7A)),
              ],
            ),
            const SizedBox(height: 14),

            // Disease risk indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: weather.riskColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: weather.riskColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco_rounded,
                      size: 16, color: weather.riskColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(weather.riskDescription,
                        style: TextStyle(
                            fontSize: 12, color: weather.riskColor,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Updated: ${DateFormat('hh:mm a').format(weather.updatedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _WeatherStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: color)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
