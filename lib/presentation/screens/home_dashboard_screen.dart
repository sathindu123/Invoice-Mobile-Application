import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/providers/business_provider.dart';
import '../../data/providers/invoice_provider.dart';
import '../widgets/invoice_card.dart';
import '../widgets/pagination_bar.dart';
import 'invoice_details_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  Future<void> _pickFromDate(BuildContext context, InvoiceProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select From Date',
    );
    if (picked != null) {
      provider.setDateRange(picked, provider.endDate);
      setState(() => _currentPage = 1);
    }
  }

  Future<void> _pickToDate(BuildContext context, InvoiceProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.endDate ?? provider.startDate ?? now,
      firstDate: provider.startDate ?? DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select To Date',
    );
    if (picked != null) {
      provider.setDateRange(provider.startDate, picked);
      setState(() => _currentPage = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
    final profile = businessProvider.profile;

    if (invoiceProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allFiltered = invoiceProvider.filteredInvoices;
    final totalItems = allFiltered.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999999);
    if (_currentPage > totalPages) {
      _currentPage = 1;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final pageInvoices = allFiltered.skip(startIndex).take(_itemsPerPage).toList();

    final dateFormat = DateFormat('dd MMM yyyy');

    return RefreshIndicator(
      onRefresh: () async => await invoiceProvider.init(),
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
                        onPressed: () {
                          invoiceProvider.setSearchQuery('');
                          setState(() => _currentPage = 1);
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                invoiceProvider.setSearchQuery(val);
                setState(() => _currentPage = 1);
              },
            ),

            const SizedBox(height: 12),

            // Date Range Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: invoiceProvider.hasDateFilter
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  // From Date Chip
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickFromDate(context, invoiceProvider),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: invoiceProvider.startDate != null
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: invoiceProvider.startDate != null
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.tr('from_date'),
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                            Text(
                              invoiceProvider.startDate != null
                                  ? dateFormat.format(invoiceProvider.startDate!)
                                  : 'Select',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: invoiceProvider.startDate != null
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: invoiceProvider.startDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
                  ),

                  // To Date Chip
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickToDate(context, invoiceProvider),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: invoiceProvider.endDate != null
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: invoiceProvider.endDate != null
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.tr('to_date'),
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                            Text(
                              invoiceProvider.endDate != null
                                  ? dateFormat.format(invoiceProvider.endDate!)
                                  : 'Select',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: invoiceProvider.endDate != null
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: invoiceProvider.endDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Clear Date Filter Button
                  if (invoiceProvider.hasDateFilter)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      tooltip: lang.tr('clear_filter'),
                      onPressed: () {
                        invoiceProvider.clearDateRange();
                        setState(() => _currentPage = 1);
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Status Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: lang.tr('all'),
                    count: invoiceProvider.countAll,
                    isSelected: invoiceProvider.selectedStatus == 'all',
                    onTap: () {
                      invoiceProvider.setStatusFilter('all');
                      setState(() => _currentPage = 1);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: lang.tr('paid'),
                    count: invoiceProvider.countPaid,
                    isSelected: invoiceProvider.selectedStatus == 'paid',
                    color: AppColors.statusPaid,
                    onTap: () {
                      invoiceProvider.setStatusFilter('paid');
                      setState(() => _currentPage = 1);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: lang.tr('pending'),
                    count: invoiceProvider.countPending,
                    isSelected: invoiceProvider.selectedStatus == 'pending',
                    color: AppColors.statusPending,
                    onTap: () {
                      invoiceProvider.setStatusFilter('pending');
                      setState(() => _currentPage = 1);
                    },
                  ),
                ],
              ),
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
                  '$totalItems ${lang.tr('invoices')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Invoices List or Empty State
            if (totalItems == 0)
              _buildEmptyState(context, lang)
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = pageInvoices[index];
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

              // Pagination Bar
              PaginationBar(
                currentPage: _currentPage,
                totalItems: totalItems,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (newPage) {
                  setState(() => _currentPage = newPage);
                },
              ),
            ],

            const SizedBox(height: 90), // Bottom padding for FAB + nav bar
          ],
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
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('total_invoiced'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              if (provider.hasDateFilter)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Filtered',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
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
              color: Colors.white.withValues(alpha: 0.12),
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
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
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
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
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
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
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
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.border,
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
              color: AppColors.primaryLight.withValues(alpha: 0.1),
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
