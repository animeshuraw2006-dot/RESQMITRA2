class Incident {
  const Incident({
    required this.id,
    required this.createdBy,
    required this.status,
    required this.risk,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.acceptedBy,
    this.createdAt,
  });

  final String id;
  final String createdBy;
  final String status;
  final String risk;
  final String category;
  final double latitude;
  final double longitude;
  final String? acceptedBy;
  final DateTime? createdAt;

  factory Incident.fromMap(Map<String, dynamic> data) {
    return Incident(
      id: data['id'] as String,
      createdBy: data['created_by'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      risk: data['risk'] as String? ?? 'standard',
      category: data['category'] as String? ?? 'Other',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      acceptedBy: data['accepted_by'] as String?,
      createdAt: data['created_at'] == null
          ? null
          : DateTime.tryParse(data['created_at'] as String),
    );
  }
}
