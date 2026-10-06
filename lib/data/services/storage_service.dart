import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_profile.dart';
import '../models/client_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';
import '../models/reminder_model.dart';

class StorageService {
  static const String _invoicesKey = 'app_invoices_list';
  static const String _clientsKey = 'app_saved_clients';
  static const String _itemsKey = 'app_saved_items';
  static const String _businessProfileKey = 'app_business_profile';
  static const String _remindersKey = 'app_reminders_list';

  // --- INVOICES ---
  static Future<List<Invoice>> loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_invoicesKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Invoice.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveInvoices(List<Invoice> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = invoices.map((inv) => inv.toJson()).toList();
    await prefs.setString(_invoicesKey, jsonEncode(jsonList));
  }

  // --- CLIENTS ---
  static Future<List<Client>> loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_clientsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Client.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = clients.map((c) => c.toJson()).toList();
    await prefs.setString(_clientsKey, jsonEncode(jsonList));
  }

  // --- ITEMS ---
  static Future<List<InvoiceItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_itemsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => InvoiceItem.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveItems(List<InvoiceItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setString(_itemsKey, jsonEncode(jsonList));
  }

  // --- BUSINESS PROFILE ---
  static Future<BusinessProfile> loadBusinessProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_businessProfileKey);
    if (jsonString == null || jsonString.isEmpty) {
      return BusinessProfile(
        name: 'My Business',
        defaultCurrency: 'LKR',
        paymentInfo: 'Payment accepted via Bank Transfer / Cash',
      );
    }

    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      return BusinessProfile.fromJson(map);
    } catch (e) {
      return BusinessProfile();
    }
  }

  static Future<void> saveBusinessProfile(BusinessProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessProfileKey, jsonEncode(profile.toJson()));
  }

  // --- REMINDERS ---
  static Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_remindersKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Reminder.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => r.toJson()).toList();
    await prefs.setString(_remindersKey, jsonEncode(jsonList));
  }
}

