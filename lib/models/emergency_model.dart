enum IncidentStatus { pending, accepted, enRoute, arrived, resolved, cancelled, failed }

enum DeliveryStatus { savedLocally, syncing, serverAccepted, responderNotified, responderAcknowledged, deliveryFailed, deliveryUnconfirmed }

class EmergencyModel {
  const EmergencyModel({
    required this.id, required this.requesterId, required this.category,
    required this.emergencyType, required this.status, required this.createdAt,
    this.urgency = 'normal', this.doNotCall = false, this.bloodGroup,
  });
  final String id;
  final String requesterId;
  final String category;
  final String emergencyType;
  final IncidentStatus status;
  final DateTime createdAt;
  final String urgency;
  final bool doNotCall;
  final String? bloodGroup;

  Map<String, dynamic> toJson() => {
    'id': id, 'requesterId': requesterId, 'category': category,
    'emergencyType': emergencyType, 'status': status.name,
    'createdAt': createdAt.toUtc().toIso8601String(), 'urgency': urgency,
    'doNotCall': doNotCall, 'bloodGroup': bloodGroup,
  };

  factory EmergencyModel.fromJson(Map<String, dynamic> json) => EmergencyModel(
    id: json['id'] as String,
    requesterId: json['requesterId'] as String,
    category: json['category'] as String,
    emergencyType: json['emergencyType'] as String,
    status: IncidentStatus.values.firstWhere(
      (v) => v.name == json['status'], orElse: () => IncidentStatus.pending,
    ),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0),
    urgency: json['urgency'] as String? ?? 'normal',
    doNotCall: json['doNotCall'] == true,
    bloodGroup: json['bloodGroup'] as String?,
  );
}
