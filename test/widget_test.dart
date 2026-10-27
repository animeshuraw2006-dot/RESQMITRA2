import 'package:flutter_test/flutter_test.dart';
import 'package:resqmitra/services.dart';

void main() {
  test('SOS message contains emergency type and a location link', () {
    final sos = Sos(
      id: 'test-sos',
      userId: 'test-user',
      category: 'General SOS',
      type: 'Medical emergency',
      name: 'Test seeker',
      phone: '9876543210',
      lat: 11.6234,
      lng: 92.7265,
      desc: 'Test-only emergency description',
    );

    expect(sos.smsText, contains('Medical emergency'));
    expect(sos.smsText, contains('Test seeker needs help'));
    expect(sos.smsText, contains('https://maps.google.com/?q=11.6234,92.7265'));
  });

  test('high-alert SOS is clearly identified in the contact message', () {
    final sos = Sos(
      id: 'test-high-alert',
      userId: 'test-user',
      category: 'High Alert SOS',
      type: 'Immediate danger',
      name: 'Test seeker',
      phone: '9876543210',
      lat: 11.6234,
      lng: 92.7265,
      highAlert: true,
    );

    expect(sos.smsText, contains('HIGH ALERT'));
  });
}
