import 'package:flutter_test/flutter_test.dart';
import 'package:resq_mitra/main.dart';

void main() {
  testWidgets('role selection screen renders', (tester) async {
    await tester.pumpWidget(const ResqMitraApp());
    expect(find.text('Choose your role'), findsOneWidget);
    expect(find.text('HELP SEEKER'), findsOneWidget);
    expect(find.text('AS RESPONDER'), findsOneWidget);
    expect(find.text('BOTH'), findsOneWidget);
  });
}
