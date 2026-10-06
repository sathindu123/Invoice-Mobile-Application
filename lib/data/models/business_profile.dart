class BusinessProfile {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String taxId;
  final String? logoPath;
  final String defaultCurrency;
  final String paymentInfo;
  final String googleScriptUrl;

  BusinessProfile({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.taxId = '',
    this.logoPath,
    this.defaultCurrency = 'LKR',
    this.paymentInfo = '',
    this.googleScriptUrl = '',
  });

  BusinessProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? logoPath,
    String? defaultCurrency,
    String? paymentInfo,
    String? googleScriptUrl,
    bool clearLogo = false,
  }) {
    return BusinessProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      googleScriptUrl: googleScriptUrl ?? this.googleScriptUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'taxId': taxId,
      'logoPath': logoPath,
      'defaultCurrency': defaultCurrency,
      'paymentInfo': paymentInfo,
      'googleScriptUrl': googleScriptUrl,
    };
  }

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      taxId: json['taxId'] as String? ?? '',
      logoPath: json['logoPath'] as String?,
      defaultCurrency: json['defaultCurrency'] as String? ?? 'LKR',
      paymentInfo: json['paymentInfo'] as String? ?? '',
      googleScriptUrl: json['googleScriptUrl'] as String? ?? '',
    );
  }
}
