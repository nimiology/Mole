import 'package:flutter_test/flutter_test.dart';
import 'package:mole_ui/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MoleApp());
    // Just verify the app can be created without errors
    expect(find.text('Mole'), findsAny);
  });
}
