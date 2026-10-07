import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'database/database_helper.dart';
import 'localization/app_localizations.dart';
import 'localization/language_controller.dart';
import 'screens/login_page.dart';
import 'services/contract_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // โหลดค่าจากไฟล์ .env ก่อนอื่น
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv load error: $e');
  }

  await DatabaseHelper.instance.database;

  // โหลดการตั้งค่าภาษาที่บันทึกไว้
  await LanguageController.instance.init();

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
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.instance.localeNotifier,
      builder: (context, currentLocale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Safa',
          theme: AppTheme.light,
          locale: currentLocale,
          supportedLocales: const [Locale('th', 'TH')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            // Apply responsive theme overrides based on screen size
            final responsiveTheme = AppTheme.responsiveLight(context);

            return Theme(
              data: responsiveTheme,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const LoginPage(),
        );
      },
    );
  }
}
