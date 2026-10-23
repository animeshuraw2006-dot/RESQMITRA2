import 'package:flutter_test/flutter_test.dart';
import 'package:resq_mitra/models/emergency_model.dart';
import 'package:resq_mitra/models/user_model.dart';

void main() {
  test('EmergencyModel serializes incident lifecycle fields', () {
    final created = DateTime.utc(2026, 10, 16, 10);
    final model = EmergencyModel(
      id: 'incident-1', requesterId: 'user-1', category: 'General SOS',
      emergencyType: 'Medical Emergency', status: IncidentStatus.pending,
      createdAt: created, doNotCall: true, bloodGroup: 'O+',
    );
    final decoded = EmergencyModel.fromJson(model.toJson());
    expect(decoded.id, 'incident-1');
    expect(decoded.status, IncidentStatus.pending);
    expect(decoded.doNotCall, isTrue);
    expect(decoded.bloodGroup, 'O+');
  });

  test('UserModel cannot grant responder privilege from client JSON', () {
    final user = UserModel.fromJson({'uid': 'u1', 'email': 'user@example.com', 'isResponder': true});
    expect(user.isResponder, isFalse);
  });
}
