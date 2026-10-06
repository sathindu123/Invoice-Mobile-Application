import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/providers/business_provider.dart';
import '../../data/providers/invoice_provider.dart';
import '../../data/services/google_sheets_service.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _taxIdController;
  late TextEditingController _paymentInfoController;
  late TextEditingController _googleScriptUrlController;

  late String _defaultCurrency;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<BusinessProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.phone);
    _emailController = TextEditingController(text: profile.email);
    _addressController = TextEditingController(text: profile.address);
    _taxIdController = TextEditingController(text: profile.taxId);
    _paymentInfoController = TextEditingController(text: profile.paymentInfo);
    _googleScriptUrlController = TextEditingController(text: profile.googleScriptUrl);
    _defaultCurrency = profile.defaultCurrency.isNotEmpty ? profile.defaultCurrency : 'LKR';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _paymentInfoController.dispose();
    _googleScriptUrlController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final business = Provider.of<BusinessProvider>(context, listen: false);
    await business.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      taxId: _taxIdController.text.trim(),
      defaultCurrency: _defaultCurrency,
      paymentInfo: _paymentInfoController.text.trim(),
      googleScriptUrl: _googleScriptUrlController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: AppColors.statusPaid,
      ),
    );
  }

  void _pickLogo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Logo Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await Provider.of<BusinessProvider>(context, listen: false)
                      .pickAndSaveLogo(ImageSource.gallery);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await Provider.of<BusinessProvider>(context, listen: false)
                      .pickAndSaveLogo(ImageSource.camera);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncWithGoogleSheets() async {
    final business = Provider.of<BusinessProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final url = _googleScriptUrlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Google Apps Script URL first')),
      );
      return;
    }

    setState(() => _isSyncing = true);

    // Save profile first
    await business.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      taxId: _taxIdController.text.trim(),
      defaultCurrency: _defaultCurrency,
      paymentInfo: _paymentInfoController.text.trim(),
      googleScriptUrl: url,
    );

    final result = await GoogleSheetsService.syncToGoogleSheets(
      webAppUrl: url,
      invoices: invoiceProvider.invoices,
      profile: business.profile,
    );

    setState(() => _isSyncing = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synced successfully with Google Sheets!'),
          backgroundColor: AppColors.statusPaid,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${result['message']}'),
          backgroundColor: AppColors.statusOverdue,
        ),
      );
    }
  }

  void _showScriptHelpModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Google Sheets Setup Guide'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Follow these steps to connect your free Google Sheet:\n'
                  '1. Open Google Sheets on your computer (sheets.new).\n'
                  '2. In menu, click Extensions > Apps Script.\n'
                  '3. Delete any code and paste the code below.\n'
                  '4. Click Deploy > New deployment.\n'
                  '5. Select "Web app". Set "Execute as" to "Me", and "Who has access" to "Anyone".\n'
                  '6. Copy the Web App URL and paste it into the field below!',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(text: GoogleSheetsService.sampleAppsScriptCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Apps Script Code copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Google Apps Script Code'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final business = Provider.of<BusinessProvider>(context);
    final profile = business.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          lang.tr('business_profile'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.check, color: AppColors.primaryLight),
            label: Text(
              lang.tr('save'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryLight),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Picker Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        image: profile.logoPath != null && File(profile.logoPath!).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(profile.logoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile.logoPath == null || !File(profile.logoPath!).existsSync()
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: AppColors.primaryLight, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Logo',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.tr('business_logo'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Will appear automatically on all invoices and PDF prints',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.upload, size: 14),
                              label: Text(
                                profile.logoPath != null ? lang.tr('change_logo') : lang.tr('upload_logo'),
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            if (profile.logoPath != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.statusOverdue, size: 18),
                                tooltip: lang.tr('remove_logo'),
                                onPressed: () async {
                                  await business.removeLogo();
                                  setState(() {});
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Business Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.tr('business_profile'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: lang.tr('business_name'),
                      prefixIcon: const Icon(Icons.business_outlined, color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: lang.tr('business_phone'),
                            prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: lang.tr('business_email'),
                            prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: lang.tr('business_address'),
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taxIdController,
                    decoration: InputDecoration(
                      labelText: lang.tr('tax_id'),
                      prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Default Currency Dropdown
                  DropdownButtonFormField<String>(
                    value: _defaultCurrency,
                    decoration: InputDecoration(
                      labelText: 'Default ${lang.tr('currency')}',
                      prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.primaryLight),
                    ),
                    items: CurrencyHelper.currencies.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['code'],
                        child: Text('${c['code']} - ${c['name']} (${c['symbol']})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _defaultCurrency = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paymentInfoController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: lang.tr('payment_info'),
                      hintText: lang.tr('payment_info_hint'),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Google Sheets Integration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.table_chart_outlined, color: Color(0xFF0F9D58), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            lang.tr('sync_google_sheets'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: AppColors.primaryLight),
                        tooltip: 'Setup Guide',
                        onPressed: _showScriptHelpModal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Backup and view your invoices in real-time in your personal Google Sheet completely free.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _googleScriptUrlController,
                    decoration: InputDecoration(
                      labelText: lang.tr('google_script_url'),
                      hintText: lang.tr('google_script_hint'),
                      prefixIcon: const Icon(Icons.link, color: Color(0xFF0F9D58)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _syncWithGoogleSheets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        _isSyncing ? 'Syncing...' : lang.tr('sync_now'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  lang.tr('save'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
