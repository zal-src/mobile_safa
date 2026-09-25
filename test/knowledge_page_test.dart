import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safa_qard/screens/knowledge_page.dart';
import 'package:safa_qard/models/user.dart';

void main() {
  testWidgets('KnowledgePage renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KnowledgePage(
            user: User(userId: 1, fullName: 'Test', email: 'test@test.com', password: 'test'),
          ),
        ),
      ),
    );

    // Verify that the title is there
    expect(find.text('ความรู้และการจัดการเงิน'), findsOneWidget);
    expect(find.text('สัญญายืมเงินคืออะไร?'), findsOneWidget);
  });
}
