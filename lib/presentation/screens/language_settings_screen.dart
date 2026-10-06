import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_translations.dart';
import '../../core/localization/language_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          lang.tr('language_settings'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App UI Language Section
            Text(
              lang.tr('app_language'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select the language displayed throughout the application interface.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: AppTranslations.supportedLanguages.map((l) {
                  final isSelected = lang.appLanguage == l['code'];
                  return RadioListTile<String>(
                    value: l['code']!,
                    groupValue: lang.appLanguage,
                    activeColor: AppColors.primary,
                    title: Text(
                      l['name']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(l['native']!),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l['code']!.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) lang.setAppLanguage(val);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // Default Invoice Bill Language Section
            Text(
              lang.tr('invoice_language'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lang.tr('invoice_language_desc'),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: AppTranslations.supportedLanguages.map((l) {
                  final isSelected = lang.invoiceLanguage == l['code'];
                  return RadioListTile<String>(
                    value: l['code']!,
                    groupValue: lang.invoiceLanguage,
                    activeColor: AppColors.primary,
                    title: Text(
                      l['name']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(l['native']!),
                    secondary: const Icon(Icons.receipt_long_outlined, color: AppColors.primaryLight),
                    onChanged: (val) {
                      if (val != null) lang.setInvoiceLanguage(val);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
