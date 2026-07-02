import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_model.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../widgets/disease_trend_chart.dart';
import '../widgets/weather_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _api = ApiService();

  List<TrendPoint> _trends = [];
  List<MonthlyPoint> _monthly = [];
  List<DiseaseRank> _ranking = [];
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
      final results = await Future.wait([
        _api.getTrends(days: 30),
        _api.getMonthly(),
        _api.getMostCommon(limit: 6),
        _api.getPredictions(),
      ]);
      final predData = results[3] as Map<String, dynamic>;
      setState(() {
        _trends  = results[0] as List<TrendPoint>;
        _monthly = results[1] as List<MonthlyPoint>;
        _ranking = results[2] as List<DiseaseRank>;
        _predictions = ((predData['predictions'] as List?) ?? [])
            .map((e) => PredictionResult.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e'),
            backgroundColor: kErrorRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analytics & Predictions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDeepGreen)),
            const Text('Disease trends, monthly statistics, and outbreak predictions',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),

            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: kDeepGreen),
              ))
            else
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return Column(children: [
                  // Row 1: Trend chart + weather
                  if (isWide)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 2, child: _ChartCard(
                        title: 'Disease Scan Trend',
                        subtitle: 'Daily total scans — last 30 days',
                        height: 240,
                        child: DiseaseTrendChart(data: _trends),
                      )),
                      const SizedBox(width: 16),
                      SizedBox(width: 300,
                        child: provider.weather != null
                            ? WeatherCard(weather: provider.weather!, onRefresh: provider.refreshWeather)
                            : const SizedBox()),
                    ])
                  else ...[
                    _ChartCard(
                      title: 'Disease Scan Trend',
                      subtitle: 'Daily total scans — last 30 days',
                      height: 220,
                      child: DiseaseTrendChart(data: _trends),
                    ),
                    const SizedBox(height: 16),
                    if (provider.weather != null)
                      WeatherCard(weather: provider.weather!),
                  ],

                  const SizedBox(height: 16),

                  // Row 2: Monthly chart + Pie chart
                  if (isWide)
                    Row(children: [
                      Expanded(child: _ChartCard(
                        title: 'Monthly Scan Statistics',
                        subtitle: 'Last 6 months — green: healthy, red: diseased',
                        height: 240,
                        child: MonthlyBarChart(data: _monthly),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _ChartCard(
                        title: 'Disease Distribution',
                        subtitle: 'All-time breakdown by disease type',
                        height: 240,
                        child: DiseasePieChart(data: _ranking),
                      )),
                    ])
                  else ...[
                    _ChartCard(
                      title: 'Monthly Scan Statistics',
                      subtitle: 'Last 6 months',
                      height: 220,
                      child: MonthlyBarChart(data: _monthly),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: 'Disease Distribution',
                      subtitle: 'All-time breakdown',
                      height: 280,
                      child: DiseasePieChart(data: _ranking),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Row 3: Predictions + Disease ranking table
                  if (isWide)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _PredictionsCard(predictions: _predictions)),
                      const SizedBox(width: 16),
                      Expanded(child: _DiseaseRankingCard(data: _ranking)),
                    ])
                  else ...[
                    _PredictionsCard(predictions: _predictions),
                    const SizedBox(height: 16),
                    _DiseaseRankingCard(data: _ranking),
                  ],
                ]);
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final double height;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle,
      required this.height, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: kDeepGreen)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(height: height, child: child),
            ],
          ),
        ),
      );
}

class _PredictionsCard extends StatelessWidget {
  final List<PredictionResult> predictions;
  const _PredictionsCard({required this.predictions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.biotech_rounded, color: kDeepGreen, size: 18),
              SizedBox(width: 8),
              Text('Disease Outbreak Predictions',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: kDeepGreen)),
            ]),
            const SizedBox(height: 4),
            const Text('Based on current weather + 7-day scan history',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            ...predictions.map((p) => _PredictionRow(prediction: p)),
          ],
        ),
      ),
    );
  }
}

class _PredictionRow extends StatefulWidget {
  final PredictionResult prediction;
  const _PredictionRow({required this.prediction});
  @override
  State<_PredictionRow> createState() => _PredictionRowState();
}

class _PredictionRowState extends State<_PredictionRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final color = riskColor(p.risk);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.disease,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${p.confidence}% confidence',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Text(p.risk,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
              ]),
            ),
          ),
          if (_expanded) Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                if (p.factors.isNotEmpty) ...[
                  const Text('Risk Factors:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 4),
                  ...p.factors.map((f) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, size: 16, color: color),
                      const SizedBox(width: 4),
                      Expanded(child: Text(f,
                          style: const TextStyle(fontSize: 12, color: Colors.black87))),
                    ],
                  )),
                  const SizedBox(height: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.recommend, size: 16, color: kDeepGreen),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.recommendation,
                          style: const TextStyle(fontSize: 12, color: Colors.black87))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiseaseRankingCard extends StatelessWidget {
  final List<DiseaseRank> data;
  const _DiseaseRankingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Disease Frequency Ranking',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kDeepGreen)),
            const Text('All-time detection counts',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            if (data.isEmpty)
              const Text('No data available',
                  style: TextStyle(color: Colors.grey))
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: kBackground),
                    children: [
                      Padding(padding: EdgeInsets.all(8),
                          child: Text('Disease', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(8),
                          child: Text('Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(8),
                          child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  ...data.asMap().entries.map((e) {
                    Color color;
                    try {
                      final hex = e.value.colorHex.replaceAll('#', '');
                      color = Color(int.parse('FF$hex', radix: 16));
                    } catch (_) { color = Colors.grey; }
                    return TableRow(children: [
                      Padding(padding: const EdgeInsets.all(8),
                          child: Row(children: [
                            Container(width: 10, height: 10,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.value.disease, style: const TextStyle(fontSize: 13))),
                          ])),
                      Padding(padding: const EdgeInsets.all(8),
                          child: Text(e.value.count.toString(),
                              style: const TextStyle(fontSize: 13))),
                      Padding(padding: const EdgeInsets.all(8),
                          child: Text('${e.value.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600))),
                    ]);
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
