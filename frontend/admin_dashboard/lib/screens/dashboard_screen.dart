import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_model.dart';
import '../models/scan_model.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../widgets/disease_trend_chart.dart';
import '../widgets/stat_card.dart';
import '../widgets/weather_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TrendPoint> _trends = [];
  List<DiseaseRank> _topDiseases = [];
  List<ScanModel> _recentScans = [];
  List<PredictionResult> _predictions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getTrends(),
        api.getMostCommon(),
        api.getScans(perPage: 8),
        api.getPredictions(),
      ]);
      final scansData = results[2] as Map<String, dynamic>;
      final predData = results[3] as Map<String, dynamic>;

      setState(() {
        _trends = results[0] as List<TrendPoint>;
        _topDiseases = results[1] as List<DiseaseRank>;
        _recentScans = ((scansData['items'] as List?) ?? [])
            .map((e) => ScanModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _predictions = ((predData['predictions'] as List?) ?? [])
            .map((e) => PredictionResult.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final overview = provider.overview;

    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshOverview();
        await provider.refreshWeather();
        await _load();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Row(children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDeepGreen)),
                Text('Overview of AgriSmartAI monitoring system',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              const Spacer(),
              Text('Last updated: ${DateFormat('hh:mm a').format(DateTime.now())}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const SizedBox(height: 24),

            // High-risk alert banner
            if (_predictions.any((p) => p.risk == 'High'))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kErrorRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kErrorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: kErrorRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('High Disease Risk Alert',
                              style: TextStyle(fontWeight: FontWeight.bold, color: kErrorRed)),
                          Text(
                            'High risk detected for: '
                            '${_predictions.where((p) => p.risk == "High").map((p) => p.disease).join(", ")}. '
                            'Advise farmers to apply preventive treatment.',
                            style: TextStyle(color: kErrorRed.withOpacity(0.8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Stats row
            if (overview != null)
              _StatsGrid(overview: overview),
            if (_loading && overview == null)
              const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: kDeepGreen),
              )),
            const SizedBox(height: 20),

            // Main grid: chart + weather + sidebar
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: Column(children: [
                      _ScanTrendCard(trends: _trends, loading: _loading),
                      const SizedBox(height: 16),
                      _RecentScansCard(scans: _recentScans, loading: _loading),
                    ])),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: Column(children: [
                      if (provider.weather != null)
                        WeatherCard(
                          weather: provider.weather!,
                          onRefresh: provider.refreshWeather,
                        ),
                      const SizedBox(height: 16),
                      _RiskPanel(predictions: _predictions),
                      const SizedBox(height: 16),
                      _TopDiseasesCard(data: _topDiseases),
                    ])),
                  ],
                );
              }
              return Column(children: [
                if (provider.weather != null)
                  WeatherCard(weather: provider.weather!, onRefresh: provider.refreshWeather),
                const SizedBox(height: 16),
                _ScanTrendCard(trends: _trends, loading: _loading),
                const SizedBox(height: 16),
                _RiskPanel(predictions: _predictions),
                const SizedBox(height: 16),
                _RecentScansCard(scans: _recentScans, loading: _loading),
                const SizedBox(height: 16),
                _TopDiseasesCard(data: _topDiseases),
              ]);
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AnalyticsOverview overview;
  const _StatsGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 500 ? 2 : 1;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          StatCard(
            title: 'Total Scans',
            value: overview.totalScans.toString(),
            subtitle: '${overview.activeScans24h} active today',
            icon: Icons.document_scanner_rounded,
            color: kDeepGreen,
          ),
          StatCard(
            title: 'Registered Farmers',
            value: overview.totalFarmers.toString(),
            subtitle: 'New Bataan, Davao de Oro',
            icon: Icons.people_rounded,
            color: const Color(0xFF1976D2),
          ),
          StatCard(
            title: 'Disease Detected',
            value: overview.diseasedScans.toString(),
            subtitle: '${overview.detectionRate.toStringAsFixed(1)}% detection rate',
            icon: Icons.warning_amber_rounded,
            color: kErrorRed,
          ),
          StatCard(
            title: 'Healthy Crops',
            value: overview.healthyScans.toString(),
            subtitle: 'No disease found',
            icon: Icons.check_circle_rounded,
            color: kLightGreen,
          ),
        ],
      );
    });
  }
}

class _ScanTrendCard extends StatelessWidget {
  final List<TrendPoint> trends;
  final bool loading;
  const _ScanTrendCard({required this.trends, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Disease Scan Trend — Last 30 Days',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kDeepGreen)),
            const SizedBox(height: 4),
            const Text('Total daily scans submitted by farmers',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: kDeepGreen))
                  : DiseaseTrendChart(data: trends),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScansCard extends StatelessWidget {
  final List<ScanModel> scans;
  final bool loading;
  const _RecentScansCard({required this.scans, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Scans',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kDeepGreen)),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: kDeepGreen),
              ))
            else if (scans.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No scans yet', style: TextStyle(color: Colors.grey))),
              )
            else
              ...scans.map((scan) => _ScanRow(scan: scan)),
          ],
        ),
      ),
    );
  }
}

class _ScanRow extends StatelessWidget {
  final ScanModel scan;
  const _ScanRow({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: scan.color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(
              scan.isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: scan.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scan.disease,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${scan.farmerName} · ${scan.farmerBarangay}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${scan.confidence.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.w700, color: scan.color, fontSize: 13)),
            Text(_fmt(scan.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _RiskPanel extends StatelessWidget {
  final List<PredictionResult> predictions;
  const _RiskPanel({required this.predictions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.biotech_rounded, color: kDeepGreen, size: 18),
              SizedBox(width: 8),
              Text('Disease Risk Forecast',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kDeepGreen)),
            ]),
            const SizedBox(height: 12),
            if (predictions.isEmpty)
              const Text('Loading predictions...', style: TextStyle(color: Colors.grey))
            else
              ...predictions.take(5).map((p) => _RiskRow(prediction: p)),
          ],
        ),
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final PredictionResult prediction;
  const _RiskRow({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final color = riskColor(prediction.risk);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(prediction.disease,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10)),
            child: Text(prediction.risk,
                style: const TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _TopDiseasesCard extends StatelessWidget {
  final List<DiseaseRank> data;
  const _TopDiseasesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Most Common Diseases',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kDeepGreen)),
            const SizedBox(height: 12),
            if (data.isEmpty)
              const Text('No data', style: TextStyle(color: Colors.grey))
            else
              ...data.take(5).map((d) {
                Color color;
                try {
                  final hex = d.colorHex.replaceAll('#', '');
                  color = Color(int.parse('FF$hex', radix: 16));
                } catch (_) {
                  color = Colors.grey;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(d.disease,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                        Text('${d.count} (${d.percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: d.percentage / 100,
                          minHeight: 6,
                          backgroundColor: color.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
