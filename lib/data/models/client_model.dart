class Client {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;

  Client({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
  });

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client &&
          runtimeType == other.runtimeType &&
          name.trim().toLowerCase() == other.name.trim().toLowerCase();

  @override
  int get hashCode => name.trim().toLowerCase().hashCode;
}
