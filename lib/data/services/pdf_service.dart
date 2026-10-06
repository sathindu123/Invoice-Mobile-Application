import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/localization/app_translations.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/date_helper.dart';
import '../models/business_profile.dart';
import '../models/invoice_model.dart';
import '../models/invoice_template.dart';

class PdfService {
  /// Generates PDF document bytes based on selected template and invoice language
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required BusinessProfile profile,
  }) async {
    final pdf = pw.Document();
    final lang = invoice.languageCode;
    final template = InvoiceTemplateOption.getById(invoice.templateId);

    // Load appropriate Unicode font based on language
    pw.Font baseFont;
    pw.Font boldFont;

    try {
      if (lang == 'si') {
        baseFont = await PdfGoogleFonts.notoSansSinhalaRegular();
        boldFont = await PdfGoogleFonts.notoSansSinhalaBold();
      } else if (lang == 'ta') {
        baseFont = await PdfGoogleFonts.notoSansTamilRegular();
        boldFont = await PdfGoogleFonts.notoSansTamilBold();
      } else {
        baseFont = await PdfGoogleFonts.interRegular();
        boldFont = await PdfGoogleFonts.interBold();
      }
    } catch (_) {
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    // Load logo if available
    pw.MemoryImage? logoImage;
    if (profile.logoPath != null && profile.logoPath!.isNotEmpty) {
      try {
        final file = File(profile.logoPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (e) {
        // Logo fallback
      }
    }

    // Helper translation
    String t(String key) => AppTranslations.translate(key, lang);

    // Primary & Accent Colors in PDF color space
    final primaryPdfColor = PdfColor.fromInt(template.primaryColor.value);
    final accentPdfColor = PdfColor.fromInt(template.accentColor.value);
    final textDark = PdfColor.fromInt(0xFF0F172A);
    final textGray = PdfColor.fromInt(0xFF64748B);
    final lightBg = PdfColor.fromInt(0xFFF8FAFC);
    final borderGray = PdfColor.fromInt(0xFFE2E8F0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (context) {
          switch (template.id) {
            case 'corporate_slate':
              return _buildCorporateTemplate(
                invoice,
                profile,
                logoImage,
                t,
                primaryPdfColor,
                accentPdfColor,
                textDark,
                textGray,
                borderGray,
              );
            case 'emerald_teal':
              return _buildEmeraldTemplate(
                invoice,
                profile,
                logoImage,
                t,
                primaryPdfColor,
                accentPdfColor,
                textDark,
                textGray,
                borderGray,
              );
            case 'minimalist_clean':
              return _buildMinimalistTemplate(
                invoice,
                profile,
                logoImage,
                t,
                textDark,
                textGray,
                borderGray,
              );
            case 'compact_receipt':
              return _buildReceiptTemplate(
                invoice,
                profile,
                logoImage,
                t,
                primaryPdfColor,
                textDark,
                textGray,
                borderGray,
              );
            case 'modern_blue':
            default:
              return _buildModernTemplate(
                invoice,
                profile,
                logoImage,
                t,
                primaryPdfColor,
                accentPdfColor,
                textDark,
                textGray,
                lightBg,
                borderGray,
              );
          }
        },
      ),
    );

    return pdf.save();
  }

  // ================= MODERN BLUE TEMPLATE =================
  static pw.Widget _buildModernTemplate(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? logoImage,
    String Function(String) t,
    PdfColor primary,
    PdfColor accent,
    PdfColor textDark,
    PdfColor textGray,
    PdfColor lightBg,
    PdfColor border,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(right: 14),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.name.isNotEmpty ? profile.name : 'Business Name',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primary),
                    ),
                    if (profile.address.isNotEmpty)
                      pw.Text(profile.address, style: pw.TextStyle(fontSize: 9, color: textGray)),
                    if (profile.phone.isNotEmpty || profile.email.isNotEmpty)
                      pw.Text('${profile.phone}  ${profile.email}', style: pw.TextStyle(fontSize: 9, color: textGray)),
                    if (profile.taxId.isNotEmpty)
                      pw.Text('${t('tax_id')}: ${profile.taxId}', style: pw.TextStyle(fontSize: 9, color: textGray)),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  t('doc_invoice'),
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primary),
                ),
                pw.SizedBox(height: 4),
                pw.Text('${t('doc_invoice_no')}: ${invoice.invoiceNumber}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark)),
                pw.Text('${t('doc_date')}: ${DateHelper.formatDisplay(invoice.date)}',
                    style: pw.TextStyle(fontSize: 9, color: textGray)),
                if (invoice.dueDate != null)
                  pw.Text('${t('doc_due_date')}: ${DateHelper.formatDisplay(invoice.dueDate!)}',
                      style: pw.TextStyle(fontSize: 9, color: textGray)),
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 6),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: invoice.status == 'paid' ? PdfColors.green100 : PdfColors.amber100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    invoice.status.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: invoice.status == 'paid' ? PdfColors.green900 : PdfColors.amber900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Divider(color: border, thickness: 1),
        pw.SizedBox(height: 12),

        // Bill To section
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: lightBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: border),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    t('doc_bill_to'),
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: accent),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.client.name.isNotEmpty ? invoice.client.name : 'Valued Customer',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textDark),
                  ),
                  if (invoice.client.phone.isNotEmpty)
                    pw.Text(invoice.client.phone, style: pw.TextStyle(fontSize: 9, color: textGray)),
                  if (invoice.client.email.isNotEmpty)
                    pw.Text(invoice.client.email, style: pw.TextStyle(fontSize: 9, color: textGray)),
                  if (invoice.client.address.isNotEmpty)
                    pw.Text(invoice.client.address, style: pw.TextStyle(fontSize: 9, color: textGray)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(t('currency'), style: pw.TextStyle(fontSize: 9, color: textGray)),
                  pw.Text(invoice.currency,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textDark)),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Items Table
        _buildItemsTable(invoice, t, primary, textDark, textGray, border),

        pw.SizedBox(height: 16),

        // Bottom Totals & Notes
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 6,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (invoice.notes.isNotEmpty) ...[
                    pw.Text(t('notes_terms'),
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primary)),
                    pw.SizedBox(height: 3),
                    pw.Text(invoice.notes, style: pw.TextStyle(fontSize: 9, color: textGray)),
                    pw.SizedBox(height: 10),
                  ],
                  if (profile.paymentInfo.isNotEmpty) ...[
                    pw.Text(t('doc_payment_details'),
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primary)),
                    pw.SizedBox(height: 3),
                    pw.Text(profile.paymentInfo, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 5,
              child: _buildTotalsCard(invoice, t, primary, textDark, textGray, border),
            ),
          ],
        ),

        pw.Spacer(),
        pw.Divider(color: border, thickness: 1),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            t('doc_thank_you'),
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: textGray),
          ),
        ),
      ],
    );
  }

  // ================= CORPORATE SLATE TEMPLATE =================
  static pw.Widget _buildCorporateTemplate(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? logoImage,
    String Function(String) t,
    PdfColor primary,
    PdfColor accent,
    PdfColor textDark,
    PdfColor textGray,
    PdfColor border,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Solid top banner
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    t('doc_invoice'),
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  ),
                  pw.Text('${t('doc_invoice_no')}: ${invoice.invoiceNumber}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey300)),
                ],
              ),
              if (logoImage != null)
                pw.Container(
                  width: 50,
                  height: 50,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
            ],
          ),
        ),

        pw.SizedBox(height: 18),

        // Company & Client in columns
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(t('doc_from'),
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: accent)),
                pw.SizedBox(height: 3),
                pw.Text(profile.name.isNotEmpty ? profile.name : 'Business Name',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textDark)),
                if (profile.address.isNotEmpty)
                  pw.Text(profile.address, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
                if (profile.phone.isNotEmpty)
                  pw.Text(profile.phone, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
                if (profile.email.isNotEmpty)
                  pw.Text(profile.email, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(t('doc_bill_to'),
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: accent)),
                pw.SizedBox(height: 3),
                pw.Text(invoice.client.name.isNotEmpty ? invoice.client.name : 'Client',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textDark)),
                if (invoice.client.phone.isNotEmpty)
                  pw.Text(invoice.client.phone, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
                if (invoice.client.email.isNotEmpty)
                  pw.Text(invoice.client.email, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
                if (invoice.client.address.isNotEmpty)
                  pw.Text(invoice.client.address, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('${t('doc_date')}: ${DateHelper.formatDisplay(invoice.date)}',
                    style: pw.TextStyle(fontSize: 9, color: textDark)),
                if (invoice.dueDate != null)
                  pw.Text('${t('doc_due_date')}: ${DateHelper.formatDisplay(invoice.dueDate!)}',
                      style: pw.TextStyle(fontSize: 9, color: textGray)),
                pw.Text('${t('currency')}: ${invoice.currency}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 20),
        _buildItemsTable(invoice, t, primary, textDark, textGray, border),
        pw.SizedBox(height: 16),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 6,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (invoice.notes.isNotEmpty) ...[
                    pw.Text(t('notes_terms'),
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                    pw.SizedBox(height: 3),
                    pw.Text(invoice.notes, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
                    pw.SizedBox(height: 8),
                  ],
                  if (profile.paymentInfo.isNotEmpty) ...[
                    pw.Text(t('doc_payment_details'),
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                    pw.SizedBox(height: 3),
                    pw.Text(profile.paymentInfo, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 5,
              child: _buildTotalsCard(invoice, t, primary, textDark, textGray, border),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Divider(color: border, thickness: 1),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(t('doc_thank_you'),
              style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic, color: textGray)),
        ),
      ],
    );
  }

  // ================= EMERALD TEAL TEMPLATE =================
  static pw.Widget _buildEmeraldTemplate(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? logoImage,
    String Function(String) t,
    PdfColor primary,
    PdfColor accent,
    PdfColor textDark,
    PdfColor textGray,
    PdfColor border,
  ) {
    return _buildModernTemplate(
      invoice,
      profile,
      logoImage,
      t,
      primary,
      accent,
      textDark,
      textGray,
      PdfColor.fromInt(0xFFF0FDFA), // Light mint surface
      border,
    );
  }

  // ================= MINIMALIST CLEAN TEMPLATE =================
  static pw.Widget _buildMinimalistTemplate(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? logoImage,
    String Function(String) t,
    PdfColor textDark,
    PdfColor textGray,
    PdfColor border,
  ) {
    final black = PdfColors.black;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              profile.name.isNotEmpty ? profile.name : 'INVOICE',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: black),
            ),
            pw.Text(
              '#${invoice.invoiceNumber}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: black),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: black, thickness: 1.5),
        pw.SizedBox(height: 10),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${t('doc_date')}: ${DateHelper.formatDisplay(invoice.date)}',
                style: pw.TextStyle(fontSize: 9, color: textGray)),
            if (invoice.dueDate != null)
              pw.Text('${t('doc_due_date')}: ${DateHelper.formatDisplay(invoice.dueDate!)}',
                  style: pw.TextStyle(fontSize: 9, color: textGray)),
          ],
        ),

        pw.SizedBox(height: 14),
        pw.Text('${t('doc_bill_to')}: ${invoice.client.name}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textDark)),
        if (invoice.client.phone.isNotEmpty)
          pw.Text(invoice.client.phone, style: pw.TextStyle(fontSize: 9, color: textGray)),
        if (invoice.client.address.isNotEmpty)
          pw.Text(invoice.client.address, style: pw.TextStyle(fontSize: 9, color: textGray)),

        pw.SizedBox(height: 16),
        _buildItemsTable(invoice, t, black, textDark, textGray, border),
        pw.SizedBox(height: 14),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 6,
              child: pw.Text(invoice.notes, style: pw.TextStyle(fontSize: 8.5, color: textGray)),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 5,
              child: _buildTotalsCard(invoice, t, black, textDark, textGray, border),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Center(
          child: pw.Text(t('doc_thank_you'),
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: textGray)),
        ),
      ],
    );
  }

  // ================= COMPACT RECEIPT TEMPLATE =================
  static pw.Widget _buildReceiptTemplate(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? logoImage,
    String Function(String) t,
    PdfColor primary,
    PdfColor textDark,
    PdfColor textGray,
    PdfColor border,
  ) {
    return pw.Center(
      child: pw.Container(
        width: 380,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            pw.Text(
              profile.name.isNotEmpty ? profile.name : 'RECEIPT',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (profile.address.isNotEmpty)
              pw.Text(profile.address, style: pw.TextStyle(fontSize: 8, color: textGray)),
            if (profile.phone.isNotEmpty)
              pw.Text(profile.phone, style: pw.TextStyle(fontSize: 8, color: textGray)),
            pw.SizedBox(height: 6),
            pw.Divider(color: textDark, thickness: 1, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 6),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${t('doc_invoice_no')}: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(DateHelper.formatDisplay(invoice.date), style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${t('doc_bill_to')}: ${invoice.client.name}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(invoice.status.toUpperCase(),
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 8),
            _buildItemsTable(invoice, t, primary, textDark, textGray, border),
            pw.SizedBox(height: 8),
            _buildTotalsCard(invoice, t, primary, textDark, textGray, border),
            pw.SizedBox(height: 12),
            pw.Divider(color: textDark, thickness: 1, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 6),
            pw.Text(t('doc_thank_you'), style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  // ================= COMMON TABLE WIDGET =================
  static pw.Widget _buildItemsTable(
    Invoice invoice,
    String Function(String) t,
    PdfColor primary,
    PdfColor textDark,
    PdfColor textGray,
    PdfColor border,
  ) {
    return pw.Table(
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: border, width: 0.5),
        horizontalInside: pw.BorderSide(color: border, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(5), // Description
        1: const pw.FlexColumnWidth(1.5), // Qty
        2: const pw.FlexColumnWidth(2.5), // Price
        3: const pw.FlexColumnWidth(2.5), // Total
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(t('doc_description'),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(t('doc_qty'),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(t('doc_price'),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(t('doc_amount'),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
          ],
        ),
        // Item Rows
        ...invoice.items.map((item) {
          final isEven = invoice.items.indexOf(item) % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColor.fromInt(0xFFFAFAFA),
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Text(item.description,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Text(item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9, color: textDark)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Text(CurrencyHelper.formatAmount(item.unitPrice, invoice.currency),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 9, color: textDark)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Text(CurrencyHelper.formatAmount(item.total, invoice.currency),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ================= TOTALS SUMMARY CARD =================
  static pw.Widget _buildTotalsCard(
    Invoice invoice,
    String Function(String) t,
    PdfColor primary,
    PdfColor textDark,
    PdfColor textGray,
    PdfColor border,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: border),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(t('doc_subtotal'), style: pw.TextStyle(fontSize: 9, color: textGray)),
              pw.Text(CurrencyHelper.formatAmount(invoice.subtotal, invoice.currency),
                  style: pw.TextStyle(fontSize: 9, color: textDark)),
            ],
          ),
          if (invoice.discountAmount > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(t('doc_discount'), style: pw.TextStyle(fontSize: 9, color: textGray)),
                pw.Text('- ${CurrencyHelper.formatAmount(invoice.discountAmount, invoice.currency)}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
              ],
            ),
          ],
          if (invoice.taxPercent > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${t('doc_tax')} (${invoice.taxPercent.toInt()}%)',
                    style: pw.TextStyle(fontSize: 9, color: textGray)),
                pw.Text(CurrencyHelper.formatAmount(invoice.taxAmount, invoice.currency),
                    style: pw.TextStyle(fontSize: 9, color: textDark)),
              ],
            ),
          ],
          pw.SizedBox(height: 6),
          pw.Divider(color: border, thickness: 1),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(t('doc_total'),
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primary)),
              pw.Text(CurrencyHelper.formatAmount(invoice.grandTotal, invoice.currency),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primary)),
            ],
          ),
        ],
      ),
    );
  }
}
