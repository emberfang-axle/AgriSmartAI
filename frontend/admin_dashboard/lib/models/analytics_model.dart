class AnalyticsOverview {
  final int totalScans;
  final int totalFarmers;
  final int activeScans24h;
  final int diseasedScans;
  final int healthyScans;
  final double detectionRate;
  final Map<String, int> diseaseBreakdown;
  final String mostCommonDisease;
  final int mostCommonCount;
  final int adminUnread;

  const AnalyticsOverview({
    required this.totalScans,
    required this.totalFarmers,
    required this.activeScans24h,
    required this.diseasedScans,
    required this.healthyScans,
    required this.detectionRate,
    required this.diseaseBreakdown,
    required this.mostCommonDisease,
    required this.mostCommonCount,
    required this.adminUnread,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      AnalyticsOverview(
        totalScans: json['total_scans'] as int? ?? 0,
        totalFarmers: json['total_farmers'] as int? ?? 0,
        activeScans24h: json['active_scans_24h'] as int? ?? 0,
        diseasedScans: json['diseased_scans'] as int? ?? 0,
        healthyScans: json['healthy_scans'] as int? ?? 0,
        detectionRate: (json['detection_rate'] as num?)?.toDouble() ?? 0,
        diseaseBreakdown: Map<String, int>.from(
            (json['disease_breakdown'] as Map<String, dynamic>?)?.map(
                    (k, v) => MapEntry(k, (v as num).toInt())) ??
                {}),
        mostCommonDisease: json['most_common_disease'] as String? ?? 'N/A',
        mostCommonCount: json['most_common_count'] as int? ?? 0,
        adminUnread: json['admin_unread'] as int? ?? 0,
      );
}

class TrendPoint {
  final String date;
  final int total;
  final Map<String, int> diseases;

  const TrendPoint({required this.date, required this.total, required this.diseases});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    final excluded = {'date', 'total'};
    final diseases = <String, int>{};
    for (final entry in json.entries) {
      if (!excluded.contains(entry.key) && entry.value is int) {
        diseases[entry.key] = entry.value as int;
      }
    }
    return TrendPoint(
      date: json['date'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      diseases: diseases,
    );
  }
}

class MonthlyPoint {
  final String label;
  final int total;
  final int diseased;
  final int healthy;
  final Map<String, int> breakdown;

  const MonthlyPoint({
    required this.label,
    required this.total,
    required this.diseased,
    required this.healthy,
    required this.breakdown,
  });

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) => MonthlyPoint(
        label: json['label'] as String? ?? '',
        total: json['total'] as int? ?? 0,
        diseased: json['diseased'] as int? ?? 0,
        healthy: json['healthy'] as int? ?? 0,
        breakdown: Map<String, int>.from(
            (json['breakdown'] as Map<String, dynamic>?)?.map(
                    (k, v) => MapEntry(k, (v as num).toInt())) ??
                {}),
      );
}

class DiseaseRank {
  final String disease;
  final int count;
  final double percentage;
  final String colorHex;

  const DiseaseRank({
    required this.disease,
    required this.count,
    required this.percentage,
    required this.colorHex,
  });

  factory DiseaseRank.fromJson(Map<String, dynamic> json) => DiseaseRank(
        disease: json['disease'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        colorHex: json['color'] as String? ?? '#2E7D32',
      );
}

class PredictionResult {
  final String disease;
  final String risk;
  final int confidence;
  final List<String> factors;
  final String recommendation;

  const PredictionResult({
    required this.disease,
    required this.risk,
    required this.confidence,
    required this.factors,
    required this.recommendation,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) =>
      PredictionResult(
        disease: json['disease'] as String? ?? '',
        risk: json['risk'] as String? ?? 'Low',
        confidence: (json['confidence'] as num?)?.toInt() ?? 0,
        factors: List<String>.from(json['factors'] as List? ?? []),
        recommendation: json['recommendation'] as String? ?? '',
      );
}
