class FarmerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String barangay;
  final String address;
  final DateTime registrationDate;
  final int totalScans;
  final int diseasedScans;
  final String? lastScan;
  final String? lastDisease;

  const FarmerModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.barangay = '',
    this.address = '',
    required this.registrationDate,
    this.totalScans = 0,
    this.diseasedScans = 0,
    this.lastScan,
    this.lastDisease,
  });

  factory FarmerModel.fromJson(Map<String, dynamic> json) => FarmerModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        barangay: json['barangay'] as String? ?? '',
        address: json['address'] as String? ?? '',
        registrationDate:
            DateTime.tryParse(json['registration_date'] as String? ?? '') ??
                DateTime.now(),
        totalScans: json['total_scans'] as int? ?? 0,
        diseasedScans: json['diseased_scans'] as int? ?? 0,
        lastScan: json['last_scan'] as String?,
        lastDisease: json['last_disease'] as String?,
      );

  double get healthRate =>
      totalScans == 0 ? 100 : ((totalScans - diseasedScans) / totalScans * 100);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
