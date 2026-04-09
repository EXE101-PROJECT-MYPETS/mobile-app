import 'package:flutter_test/flutter_test.dart';

import 'package:petpee_mobile/main.dart';

void main() {
  testWidgets('Shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('PETPEES'), findsOneWidget);
  });
}
