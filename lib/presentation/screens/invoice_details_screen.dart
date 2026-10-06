import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_translations.dart';
import '../../core/localization/language_provider.dart';
import '../../data/providers/business_provider.dart';
import '../../data/providers/invoice_provider.dart';
import '../../data/services/pdf_service.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);

    final invoiceIndex = invoiceProvider.invoices.indexWhere((i) => i.id == widget.invoiceId);
    if (invoiceIndex < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: const Center(child: Text('Invoice not found')),
      );
    }

    final invoice = invoiceProvider.invoices[invoiceIndex];
    final profile = businessProvider.profile;
    final isPaid = invoice.status.toLowerCase() == 'paid';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: lang.tr('edit'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateInvoiceScreen(invoiceToEdit: invoice),
                ),
              );
            },
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.statusOverdue),
            tooltip: lang.tr('delete'),
            onPressed: () => _confirmDelete(context, invoiceProvider, invoice.id, lang),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Quick Status & Language Controls Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Toggle
                GestureDetector(
                  onTap: () {
                    final nextStatus = isPaid ? 'pending' : 'paid';
                    invoiceProvider.updateStatus(invoice.id, nextStatus);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.statusPaid.withOpacity(0.12)
                          : AppColors.statusPending.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPaid ? AppColors.statusPaid : AppColors.statusPending,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: isPaid ? AppColors.statusPaid : AppColors.statusPending,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPaid ? lang.tr('paid') : lang.tr('pending'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? AppColors.statusPaid : AppColors.statusPending,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.sync_alt, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),

                // Change Language of this Bill Dropdown
                Row(
                  children: [
                    const Icon(Icons.translate, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: invoice.languageCode,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      items: AppTranslations.supportedLanguages.map((l) {
                        return DropdownMenuItem<String>(
                          value: l['code'],
                          child: Text(
                            l['name']!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (newLang) {
                        if (newLang != null) {
                          invoiceProvider.saveInvoice(
                            invoice.copyWith(languageCode: newLang),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // High Performance PDF Preview
          Expanded(
            child: PdfPreview(
              build: (format) => PdfService.generateInvoicePdf(
                invoice: invoice,
                profile: profile,
              ),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              allowSharing: true,
              allowPrinting: true,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: '${invoice.invoiceNumber}.pdf',
              previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              loadingWidget: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    InvoiceProvider provider,
    String id,
    LanguageProvider lang,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.tr('delete')),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOverdue),
            onPressed: () {
              provider.deleteInvoice(id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(lang.tr('delete')),
          ),
        ],
      ),
    );
  }
}
