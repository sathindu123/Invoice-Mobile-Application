import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../data/providers/business_provider.dart';
import '../../data/providers/reminder_provider.dart';
import 'home_dashboard_screen.dart';
import 'reminders_screen.dart';
import 'manage_contacts_screen.dart';
import 'business_settings_screen.dart';
import 'language_settings_screen.dart';
import 'create_invoice_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    RemindersScreen(),
    ManageContactsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
    final reminderProvider = Provider.of<ReminderProvider>(context);
    final profile = businessProvider.profile;

    final overdueCount = reminderProvider.overdueCount;
    final todayCount = reminderProvider.todayReminders.length;
    final reminderBadge = overdueCount + todayCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo
            if (profile.logoPath != null && File(profile.logoPath!).existsSync())
              Container(
                width: 38, height: 38,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  image: DecorationImage(image: FileImage(File(profile.logoPath!)), fit: BoxFit.cover),
                ),
              )
            else
              Container(
                width: 38, height: 38,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name.isNotEmpty ? profile.name : lang.tr('app_name'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getPageTitle(_currentIndex, lang),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_outlined),
            tooltip: lang.tr('language_settings'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: lang.tr('settings'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessSettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(lang.tr('create_invoice'), style: const TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: lang.tr('invoices'),
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.alarm_outlined,
                  activeIcon: Icons.alarm,
                  label: 'Reminders',
                  index: 1,
                  badge: reminderBadge,
                ),
                _buildNavItem(
                  icon: Icons.domain_outlined,
                  activeIcon: Icons.domain,
                  label: lang.tr('entities'),
                  index: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPageTitle(int index, LanguageProvider lang) {
    switch (index) {
      case 0: return lang.tr('dashboard');
      case 1: return 'Reminders & Notices';
      case 2: return 'Entities (Customers & Items)';
      default: return lang.tr('dashboard');
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    int badge = 0,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          badge > 9 ? '9+' : badge.toString(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
