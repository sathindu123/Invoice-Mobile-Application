import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/providers/business_provider.dart';
import '../../data/providers/invoice_provider.dart';
import '../widgets/invoice_card.dart';
import 'business_settings_screen.dart';
import 'create_invoice_screen.dart';
import 'invoice_details_screen.dart';
import 'language_settings_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
    final profile = businessProvider.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            if (profile.logoPath != null && File(profile.logoPath!).existsSync())
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  image: DecorationImage(
                    image: FileImage(File(profile.logoPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 38,
                height: 38,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    lang.tr('dashboard'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Quick Button
          IconButton(
            icon: const Icon(Icons.translate_outlined),
            tooltip: lang.tr('language_settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
              );
            },
          ),
          // Business Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: lang.tr('settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          lang.tr('create_invoice'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await invoiceProvider.init();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Overview Cards
              _buildStatsRow(context, invoiceProvider, profile.defaultCurrency, lang),

              const SizedBox(height: 20),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: lang.tr('search'),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: invoiceProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => invoiceProvider.setSearchQuery(''),
                        )
                      : null,
                ),
                onChanged: (val) => invoiceProvider.setSearchQuery(val),
              ),

              const SizedBox(height: 14),

              // Status Filter Tabs
              Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: lang.tr('all'),
                    count: invoiceProvider.invoices.length,
                    isSelected: invoiceProvider.selectedStatus == 'all',
                    onTap: () => invoiceProvider.setStatusFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: lang.tr('paid'),
                    count: invoiceProvider.invoices.where((i) => i.status == 'paid').length,
                    isSelected: invoiceProvider.selectedStatus == 'paid',
                    color: AppColors.statusPaid,
                    onTap: () => invoiceProvider.setStatusFilter('paid'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: lang.tr('pending'),
                    count: invoiceProvider.invoices.where((i) => i.status == 'pending').length,
                    isSelected: invoiceProvider.selectedStatus == 'pending',
                    color: AppColors.statusPending,
                    onTap: () => invoiceProvider.setStatusFilter('pending'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.tr('recent_invoices'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${invoiceProvider.filteredInvoices.length} ${lang.tr('invoices')}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Invoices List or Empty State
              if (invoiceProvider.filteredInvoices.isEmpty)
                _buildEmptyState(context, lang)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoiceProvider.filteredInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoiceProvider.filteredInvoices[index];
                    return InvoiceCard(
                      invoice: invoice,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceDetailsScreen(invoiceId: invoice.id),
                          ),
                        );
                      },
                      onStatusToggle: () {
                        final nextStatus = invoice.status == 'paid' ? 'pending' : 'paid';
                        invoiceProvider.updateStatus(invoice.id, nextStatus);
                      },
                    );
                  },
                ),

              const SizedBox(height: 70), // Bottom padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    InvoiceProvider provider,
    String currency,
    LanguageProvider lang,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.tr('total_invoiced'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyHelper.formatAmount(provider.totalInvoiced, currency),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Paid
                Row(
                  children: [
                    const CircleAvatar(radius: 4, backgroundColor: Color(0xFF34D399)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.tr('paid_amount'),
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                        ),
                        Text(
                          CurrencyHelper.formatAmount(provider.totalPaid, currency),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(width: 1, height: 28, color: Colors.white.withOpacity(0.2)),
                // Pending
                Row(
                  children: [
                    const CircleAvatar(radius: 4, backgroundColor: Color(0xFFFBBF24)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.tr('unpaid_amount'),
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                        ),
                        Text(
                          CurrencyHelper.formatAmount(provider.totalPending, currency),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required int count,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageProvider lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 16),
          Text(
            lang.tr('no_invoices_yet'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            lang.tr('create_first_invoice'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
