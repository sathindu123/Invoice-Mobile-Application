import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _appLanguageKey = 'app_language';
  static const String _invoiceLanguageKey = 'invoice_default_language';

  String _appLanguage = 'en';
  String _invoiceLanguage = 'en';

  String get appLanguage => _appLanguage;
  String get invoiceLanguage => _invoiceLanguage;

  LanguageProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _appLanguage = prefs.getString(_appLanguageKey) ?? 'en';
    _invoiceLanguage = prefs.getString(_invoiceLanguageKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setAppLanguage(String code) async {
    if (_appLanguage == code) return;
    _appLanguage = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appLanguageKey, code);
  }

  Future<void> setInvoiceLanguage(String code) async {
    if (_invoiceLanguage == code) return;
    _invoiceLanguage = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_invoiceLanguageKey, code);
  }

  String tr(String key) {
    return AppTranslations.translate(key, _appLanguage);
  }

  String trDoc(String key, [String? overrideLang]) {
    return AppTranslations.translate(key, overrideLang ?? _invoiceLanguage);
  }
}
