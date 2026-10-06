import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/business_profile.dart';
import '../services/storage_service.dart';

class BusinessProvider extends ChangeNotifier {
  BusinessProfile _profile = BusinessProfile();
  bool _isLoading = true;

  BusinessProfile get profile => _profile;
  bool get isLoading => _isLoading;

  BusinessProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _profile = await StorageService.loadBusinessProfile();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? defaultCurrency,
    String? paymentInfo,
    String? googleScriptUrl,
  }) async {
    _profile = _profile.copyWith(
      name: name,
      phone: phone,
      email: email,
      address: address,
      taxId: taxId,
      defaultCurrency: defaultCurrency,
      paymentInfo: paymentInfo,
      googleScriptUrl: googleScriptUrl,
    );
    notifyListeners();
    await StorageService.saveBusinessProfile(_profile);
  }

  Future<bool> pickAndSaveLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return false;

      // Save locally to App documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'business_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      _profile = _profile.copyWith(logoPath: savedImage.path);
      notifyListeners();
      await StorageService.saveBusinessProfile(_profile);
      return true;
    } catch (e) {
      debugPrint('Error picking logo: $e');
      return false;
    }
  }

  Future<void> removeLogo() async {
    if (_profile.logoPath != null) {
      try {
        final file = File(_profile.logoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _profile = _profile.copyWith(clearLogo: true);
    notifyListeners();
    await StorageService.saveBusinessProfile(_profile);
  }
}
