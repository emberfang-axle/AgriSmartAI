import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/disease_result.dart';
import '../providers/detection_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/notification_badge.dart';
import 'camera_screen.dart';
import 'notification_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('AgriSmartAI'),
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.eco_rounded, color: kWarmGold, size: 28),
        ),
        actions: [
          NotificationBadge(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProv, _) => RefreshIndicator(
        color: kDeepGreen,
        onRefresh: () => weatherProv.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingCard(),
              const SizedBox(height: 16),
              _WeatherWidget(provider: weatherProv),
              const SizedBox(height: 20),
              _ScanCard(),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Recent Scans'),
              const SizedBox(height: 12),
              const _RecentScans(),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Quick Tips'),
              const SizedBox(height: 12),
              const _TipsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kDeepGreen, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kDeepGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Farmer!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Consumer<NotificationProvider>(
                  builder: (_, p, __) => Text(
                    p.hasUnread
                        ? '${p.unreadCount} new alert${p.unreadCount > 1 ? 's' : ''} — check notifications'
                        : 'All clear. Keep monitoring your crops.',
                    style: const TextStyle(
                      color: kWarmGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.grass_rounded, color: Colors.white24, size: 64),
        ],
      ),
    );
  }
}

class _WeatherWidget extends StatelessWidget {
  final WeatherProvider provider;
  const _WeatherWidget({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loading && provider.weather == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: kDeepGreen, strokeWidth: 2)),
      );
    }

    final w = provider.weather;
    if (w == null) return const SizedBox.shrink();

    final riskColor = w.diseaseRisk == 'High'
        ? kErrorRed
        : w.diseaseRisk == 'Moderate'
            ? kWarningOrange
            : kLightGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.wb_sunny_rounded, color: kWarmGold, size: 18),
            const SizedBox(width: 6),
            const Text('Current Weather — New Bataan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDeepGreen)),
            const Spacer(),
            Text(w.icon, style: const TextStyle(fontSize: 20)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _WeatherStat('${w.temperature.toStringAsFixed(1)}°C',
                'Temperature', Icons.thermostat)),
            Expanded(child: _WeatherStat('${w.humidity}%', 'Humidity', Icons.water_drop)),
            Expanded(child: _WeatherStat('${w.precipitationProbability}%',
                'Rain Chance', Icons.umbrella)),
            Expanded(child: _WeatherStat('${w.windSpeed.toStringAsFixed(1)} km/h',
                'Wind', Icons.air)),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: riskColor.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.biotech_rounded, size: 13, color: riskColor),
              const SizedBox(width: 5),
              Text('Disease Risk: ${w.diseaseRisk}',
                  style: TextStyle(fontSize: 12, color: riskColor, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _WeatherStat(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 14, color: Colors.grey),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
  ]);
}

class _ScanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      ),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kWarmGold.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.camera_alt_rounded,
                size: 140,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'Scan Rice Leaf',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Point camera at leaf to detect disease',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kDeepGreen,
      ),
    );
  }
}

class _RecentScans extends StatelessWidget {
  const _RecentScans();

  @override
  Widget build(BuildContext context) {
    return Consumer<DetectionProvider>(
      builder: (context, provider, _) {
        final history = provider.history.take(5).toList();
        if (history.isEmpty) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.document_scanner_outlined,
                      color: Colors.grey, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No scans yet. Tap Scan Leaf to start.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: history
              .map((r) => _RecentScanTile(result: r))
              .toList(),
        );
      },
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  final DiseaseResult result;
  const _RecentScanTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: result.color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: result.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.isHealthy
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: result.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.disease,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${result.confidence.toStringAsFixed(1)}% confidence  •  ${_formatDate(result.timestamp)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: result.severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                result.severity,
                style: TextStyle(
                  color: result.severityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _TipsSection extends StatelessWidget {
  const _TipsSection();

  static const _tips = [
    (
      icon: Icons.water_drop_outlined,
      title: 'Water Management',
      body: 'Maintain 2–5 cm standing water during vegetative stage.'
    ),
    (
      icon: Icons.science_outlined,
      title: 'Early Treatment',
      body: 'Apply fungicides within 48 hours of first disease signs.'
    ),
    (
      icon: Icons.calendar_today_outlined,
      title: 'Scout Twice Weekly',
      body: 'Regular monitoring catches disease before it spreads.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tips
          .map((t) => _TipCard(icon: t.icon, title: t.title, body: t.body))
          .toList(),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kDeepGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kDeepGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: kDeepGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
