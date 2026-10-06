import 'client_model.dart';
import 'invoice_item_model.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final DateTime? dueDate;
  final Client client;
  final List<InvoiceItem> items;
  final String currency;
  final String templateId;
  final String languageCode;
  final String status; // 'paid', 'pending', 'overdue', 'draft'
  final double taxPercent;
  final String notes;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    this.dueDate,
    required this.client,
    required this.items,
    this.currency = 'LKR',
    this.templateId = 'modern_blue',
    this.languageCode = 'en',
    this.status = 'pending',
    this.taxPercent = 0.0,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get discountAmount => items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get itemsTotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get taxAmount => itemsTotal * (taxPercent / 100);
  double get grandTotal => itemsTotal + taxAmount;

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? date,
    DateTime? dueDate,
    Client? client,
    List<InvoiceItem>? items,
    String? currency,
    String? templateId,
    String? languageCode,
    String? status,
    double? taxPercent,
    String? notes,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      client: client ?? this.client,
      items: items ?? this.items,
      currency: currency ?? this.currency,
      templateId: templateId ?? this.templateId,
      languageCode: languageCode ?? this.languageCode,
      status: status ?? this.status,
      taxPercent: taxPercent ?? this.taxPercent,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'client': client.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'currency': currency,
      'templateId': templateId,
      'languageCode': languageCode,
      'status': status,
      'taxPercent': taxPercent,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'grandTotal': grandTotal,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
      client: Client.fromJson(Map<String, dynamic>.from(json['client'] as Map? ?? {})),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => InvoiceItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      currency: json['currency'] as String? ?? 'LKR',
      templateId: json['templateId'] as String? ?? 'modern_blue',
      languageCode: json['languageCode'] as String? ?? 'en',
      status: json['status'] as String? ?? 'pending',
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
