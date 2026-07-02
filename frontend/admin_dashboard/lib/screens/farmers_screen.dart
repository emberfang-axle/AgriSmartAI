import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/farmer_model.dart';
import '../services/api_service.dart';
import 'farmer_detail_screen.dart';

class FarmersScreen extends StatefulWidget {
  const FarmersScreen({super.key});
  @override
  State<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends State<FarmersScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  List<FarmerModel> _farmers = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _loading = false;
  String _search = '';

  static const _perPage = 10;

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
      final data = await _api.getFarmers(
        page: _page, perPage: _perPage, search: _search);
      final items = (data['items'] as List? ?? [])
          .map((e) => FarmerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _farmers = items;
        _total = data['total'] as int? ?? 0;
        _totalPages = data['pages'] as int? ?? 1;
      });
    } catch (e) {
      _showError('Failed to load farmers: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: kErrorRed));
  }

  void _showAddFarmerDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final barangayCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Register New Farmer',
            style: TextStyle(color: kDeepGreen, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _Field(ctrl: nameCtrl, label: 'Full Name *', icon: Icons.person_rounded),
              const SizedBox(height: 12),
              _Field(ctrl: emailCtrl, label: 'Email *', icon: Icons.email_rounded,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _Field(ctrl: phoneCtrl, label: 'Phone Number', icon: Icons.phone_rounded,
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              _Field(ctrl: barangayCtrl, label: 'Barangay', icon: Icons.location_on_rounded),
              const SizedBox(height: 12),
              _Field(ctrl: addressCtrl, label: 'Full Address', icon: Icons.home_rounded),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                _showError('Name and email are required');
                return;
              }
              try {
                await _api.createFarmer({
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'barangay': barangayCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Farmer registered successfully!'),
                      backgroundColor: kLightGreen));
              } catch (e) {
                _showError(e.toString().contains('409')
                    ? 'Email already registered'
                    : 'Failed to register farmer');
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Farmer Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDeepGreen)),
              Text('View and manage registered farmers',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddFarmerDialog,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Register Farmer'),
            ),
          ]),
          const SizedBox(height: 20),

          // Search bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search farmers by name, email, or barangay...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      filled: false,
                    ),
                    onSubmitted: (v) {
                      _search = v;
                      _page = 1;
                      _load();
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _search = _searchCtrl.text;
                    _page = 1;
                    _load();
                  },
                  child: const Text('Search'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    _search = '';
                    _page = 1;
                    _load();
                  },
                  child: const Text('Clear'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      '$_total farmer${_total != 1 ? "s" : ""} found',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: kDeepGreen))
                        : _farmers.isEmpty
                            ? const Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No farmers found', style: TextStyle(color: Colors.grey)),
                                ]))
                            : ListView.separated(
                                itemCount: _farmers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) => _FarmerRow(
                                  farmer: _farmers[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FarmerDetailScreen(
                                          farmerId: _farmers[i].id,
                                          farmerName: _farmers[i].name),
                                    ),
                                  ).then((_) => _load()),
                                ),
                              ),
                  ),
                  const Divider(height: 1),
                  // Pagination
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(children: [
                      Text('Page $_page of $_totalPages',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _page > 1 ? () { _page--; _load(); } : null,
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: const Text('Prev'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _page < _totalPages ? () { _page++; _load(); } : null,
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: const Text('Next'),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerRow extends StatelessWidget {
  final FarmerModel farmer;
  final VoidCallback onTap;
  const _FarmerRow({required this.farmer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kDeepGreen.withOpacity(0.1),
              child: Text(farmer.initials,
                  style: const TextStyle(color: kDeepGreen, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(farmer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(farmer.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            Expanded(flex: 2, child: Text(farmer.barangay,
                style: const TextStyle(fontSize: 13))),
            Expanded(flex: 1, child: Text(farmer.totalScans.toString(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            Expanded(flex: 2, child: farmer.lastDisease != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: diseaseColor(farmer.lastDisease!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(farmer.lastDisease!,
                        style: TextStyle(
                          color: diseaseColor(farmer.lastDisease!),
                          fontSize: 12, fontWeight: FontWeight.w500)))
                : const Text('No scans', style: TextStyle(color: Colors.grey, fontSize: 12))),
            Expanded(flex: 2, child: Text(
              farmer.registrationDate.isAfter(DateTime(2000))
                  ? DateFormat('MMM d, y').format(farmer.registrationDate)
                  : '—',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            )),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
      );
}
