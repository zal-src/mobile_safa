import 'package:flutter/material.dart';
import '../localization/language_controller.dart';
import '../theme/app_theme.dart';

class LanguageSwitchButton extends StatelessWidget {
  final bool isCompact;

  const LanguageSwitchButton({
    super.key,
    this.isCompact = true,
  });

  void _showLanguageDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final current = LanguageController.instance.currentLocale.languageCode;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'เลือกภาษา / Select Language',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageOptionTile(
                  flag: '🇹🇭',
                  title: 'ภาษาไทย (Thai)',
                  isSelected: current == 'th',
                  onTap: () {
                    LanguageController.instance.changeLanguage(
                      LanguageController.thLocale,
                    );
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _LanguageOptionTile(
                  flag: '🇬🇧',
                  title: 'English (อังกฤษ)',
                  isSelected: current == 'en',
                  onTap: () {
                    LanguageController.instance.changeLanguage(
                      LanguageController.enLocale,
                    );
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.instance.localeNotifier,
      builder: (context, locale, _) {
        final isThai = locale.languageCode == 'th';

        return Tooltip(
          message: isThai ? 'เปลี่ยนภาษา (Change Language)' : 'Switch Language',
          child: InkWell(
            onTap: () => LanguageController.instance.toggleLanguage(),
            onLongPress: () => _showLanguageDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBorder, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isThai ? '🇹🇭' : '🇬🇧',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isThai ? 'TH' : 'EN',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String flag;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.flag,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.ink,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      tileColor: isSelected ? AppColors.primarySoft : Colors.white,
      onTap: onTap,
    );
  }
}
