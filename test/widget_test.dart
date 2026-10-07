import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safa_qard/localization/app_localizations.dart';
import 'package:safa_qard/screens/login_page.dart';

void main() {
  testWidgets('shows the login screen in Thai only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('th', 'TH'),
        supportedLocales: const [Locale('th', 'TH')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Safa'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsWidgets);
    expect(find.text('อีเมล'), findsOneWidget);
    expect(find.text('รหัสผ่าน'), findsOneWidget);
    expect(find.byTooltip('แสดงรหัสผ่าน'), findsOneWidget);
    expect(find.text('Log In'), findsNothing);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Password'), findsNothing);
    expect(find.byTooltip('Show password'), findsNothing);
  });
}
