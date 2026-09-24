import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'screens/login_page.dart';
import 'services/contract_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

  try {
    await ContractService().migrateOldAgreementIds();
  } catch (e) {
    debugPrint('Agreement ID migration error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safa',
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
