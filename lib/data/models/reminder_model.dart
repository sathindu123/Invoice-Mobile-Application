import 'dart:convert';

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime reminderDate;
  final String clientName;
  final String clientPhone;
  final String itemDescription;
  final double amount;
  final String currency;
  final bool isCompleted;
  final bool notificationEnabled;
  final int? notificationId;

  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.reminderDate,
    this.clientName = '',
    this.clientPhone = '',
    this.itemDescription = '',
    this.amount = 0.0,
    this.currency = 'LKR',
    this.isCompleted = false,
    this.notificationEnabled = true,
    this.notificationId,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? reminderDate,
    String? clientName,
    String? clientPhone,
    String? itemDescription,
    double? amount,
    String? currency,
    bool? isCompleted,
    bool? notificationEnabled,
    int? notificationId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderDate: reminderDate ?? this.reminderDate,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      itemDescription: itemDescription ?? this.itemDescription,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'reminderDate': reminderDate.toIso8601String(),
        'clientName': clientName,
        'clientPhone': clientPhone,
        'itemDescription': itemDescription,
        'amount': amount,
        'currency': currency,
        'isCompleted': isCompleted,
        'notificationEnabled': notificationEnabled,
        'notificationId': notificationId,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        reminderDate: DateTime.parse(json['reminderDate']),
        clientName: json['clientName'] ?? '',
        clientPhone: json['clientPhone'] ?? '',
        itemDescription: json['itemDescription'] ?? '',
        amount: (json['amount'] ?? 0.0).toDouble(),
        currency: json['currency'] ?? 'LKR',
        isCompleted: json['isCompleted'] ?? false,
        notificationEnabled: json['notificationEnabled'] ?? true,
        notificationId: json['notificationId'],
      );

  static String encodeList(List<Reminder> reminders) =>
      jsonEncode(reminders.map((r) => r.toJson()).toList());

  static List<Reminder> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => Reminder.fromJson(e)).toList();
  }
}
