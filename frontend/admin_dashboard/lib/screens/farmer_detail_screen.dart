import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/farmer_model.dart';
import '../models/scan_model.dart';
import '../services/api_service.dart';

class FarmerDetailScreen extends StatefulWidget {
  final String farmerId;
  final String farmerName;
  const FarmerDetailScreen({super.key, required this.farmerId, required this.farmerName});

  @override
  State<FarmerDetailScreen> createState() => _FarmerDetailScreenState();
}

class _FarmerDetailScreenState extends State<FarmerDetailScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  FarmerModel? _farmer;
  List<ScanModel> _scans = [];
  int _page = 1, _totalPages = 1, _total = 0;
  bool _loading = true;
  String _search = '';
  String _diseaseFilter = '';
  String _sort = 'newest';
  String _dateFrom = '';
  String _dateTo = '';

  static const _perPage = 10;
  static const _diseases = [
    'All', 'Healthy', 'Leaf Blast', 'Bacterial Leaf Blight',
    'Brown Spot', 'Sheath Blight', 'Tungro Virus',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getFarmer(widget.farmerId),
        _api.getFarmerScans(
          widget.farmerId,
          page: _page, perPage: _perPage,
          disease: _diseaseFilter,
          dateFrom: _dateFrom, dateTo: _dateTo,
          sort: _sort, search: _search,
        ),
      ]);
      final farmerData = results[0] as FarmerModel;
      final scansData = results[1] as Map<String, dynamic>;

      setState(() {
        _farmer = farmerData;
        _scans = ((scansData['items'] as List?) ?? [])
            .map((e) => ScanModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _total = scansData['total'] as int? ?? 0;
        _totalPages = scansData['pages'] as int? ?? 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(widget.farmerName),
        backgroundColor: kDeepGreen,
        foregroundColor: Colors.white,
      ),
      body: _loading && _farmer == null
          ? const Center(child: CircularProgressIndicator(color: kDeepGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_farmer != null) _FarmerProfile(farmer: _farmer!),
                  const SizedBox(height: 20),
                  _ScanHistorySection(
                    scans: _scans,
                    total: _total,
                    page: _page,
                    totalPages: _totalPages,
                    loading: _loading,
                    searchCtrl: _searchCtrl,
                    diseaseFilter: _diseaseFilter,
                    sort: _sort,
                    diseases: _diseases,
                    onSearch: (v) {
                      _search = v; _page = 1; _load();
                    },
                    onDiseaseChanged: (d) {
                      _diseaseFilter = d == 'All' ? '' : d;
                      _page = 1; _load();
                    },
                    onSortChanged: (s) { _sort = s!; _load(); },
                    onPrev: _page > 1 ? () { _page--; _load(); } : null,
                    onNext: _page < _totalPages ? () { _page++; _load(); } : null,
                  ),
                ],
              ),
            ),
    );
  }
}

class _FarmerProfile extends StatelessWidget {
  final FarmerModel farmer;
  const _FarmerProfile({required this.farmer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: kDeepGreen.withOpacity(0.1),
                child: Text(farmer.initials,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold, color: kDeepGreen)),
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(farmer.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kDeepGreen)),
                Text(farmer.barangay.isNotEmpty ? '${farmer.barangay}, New Bataan' : 'New Bataan',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _InfoChip(icon: Icons.email_rounded, label: farmer.email),
                  if (farmer.phone.isNotEmpty)
                    _InfoChip(icon: Icons.phone_rounded, label: farmer.phone),
                  if (farmer.address.isNotEmpty)
                    _InfoChip(icon: Icons.home_rounded, label: farmer.address),
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Registered: ${DateFormat('MMM d, y').format(farmer.registrationDate)}',
                  ),
                ]),
              ])),
            ]),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            // Stats
            Row(children: [
              _StatBadge(label: 'Total Scans', value: farmer.totalScans.toString(),
                  color: kDeepGreen),
              const SizedBox(width: 16),
              _StatBadge(label: 'Diseased', value: farmer.diseasedScans.toString(),
                  color: kErrorRed),
              const SizedBox(width: 16),
              _StatBadge(
                label: 'Healthy Rate',
                value: '${farmer.healthRate.toStringAsFixed(1)}%',
                color: kLightGreen,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: kDeepGreen),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      );
}

class _ScanHistorySection extends StatelessWidget {
  final List<ScanModel> scans;
  final int total, page, totalPages;
  final bool loading;
  final TextEditingController searchCtrl;
  final String diseaseFilter, sort;
  final List<String> diseases;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onDiseaseChanged;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback? onPrev, onNext;

  const _ScanHistorySection({
    required this.scans, required this.total, required this.page,
    required this.totalPages, required this.loading, required this.searchCtrl,
    required this.diseaseFilter, required this.sort, required this.diseases,
    required this.onSearch, required this.onDiseaseChanged,
    required this.onSortChanged, this.onPrev, this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDeepGreen)),
            const SizedBox(height: 16),
            // Filters row
            Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search scans...',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onSubmitted: onSearch,
                ),
              ),
              DropdownButton<String>(
                value: diseaseFilter.isEmpty ? 'All' : diseaseFilter,
                hint: const Text('Disease'),
                items: diseases.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => onDiseaseChanged(v!),
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(10),
              ),
              DropdownButton<String>(
                value: sort,
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                ],
                onChanged: onSortChanged,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(10),
              ),
            ]),
            const SizedBox(height: 16),
            Text('$total scan${total != 1 ? "s" : ""} found',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            if (loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: kDeepGreen),
              ))
            else if (scans.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No scans found', style: TextStyle(color: Colors.grey)),
              ))
            else ...[
              ...scans.map((scan) => _ScanDetailRow(scan: scan)),
              const Divider(),
              Row(children: [
                Text('Page $page of $totalPages',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const Spacer(),
                if (onPrev != null)
                  OutlinedButton(onPressed: onPrev, child: const Text('← Prev')),
                const SizedBox(width: 8),
                if (onNext != null)
                  OutlinedButton(onPressed: onNext, child: const Text('Next →')),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanDetailRow extends StatelessWidget {
  final ScanModel scan;
  const _ScanDetailRow({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scan.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: scan.color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(
                scan.isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                color: scan.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(scan.disease,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(DateFormat('MMM d, y — hh:mm a').format(scan.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${scan.confidence.toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: scan.color, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scan.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(scan.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold, color: scan.statusColor)),
              ),
            ]),
          ]),
          if (scan.weatherTemp != null) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 12, children: [
              _WeatherTag(Icons.thermostat, '${scan.weatherTemp}°C'),
              _WeatherTag(Icons.water_drop, '${scan.weatherHumidity}%'),
              _WeatherTag(Icons.umbrella, '${scan.weatherPrecip}% rain'),
              if (scan.weatherCondition != null)
                _WeatherTag(Icons.wb_cloudy, scan.weatherCondition!),
            ]),
          ],
          if (!scan.isHealthy && scan.treatment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('💊 ${scan.treatment}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}

class _WeatherTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WeatherTag(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]);
}
