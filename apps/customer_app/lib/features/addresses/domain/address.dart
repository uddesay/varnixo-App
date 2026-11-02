class Address {
  const Address({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.line1,
    required this.city,
    required this.state,
    required this.postalCode,
    this.label = 'home',
    this.line2,
    this.landmark,
    this.country = 'IN',
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String,
        label: json['label'] as String? ?? 'home',
        recipientName: json['recipient_name'] as String,
        recipientPhone: json['recipient_phone'] as String,
        line1: json['line1'] as String,
        line2: json['line2'] as String?,
        landmark: json['landmark'] as String?,
        city: json['city'] as String,
        state: json['state'] as String,
        postalCode: json['postal_code'] as String,
        country: json['country'] as String? ?? 'IN',
        isDefault: json['is_default'] as bool? ?? false,
      );

  final String id;
  final String label;
  final String recipientName;
  final String recipientPhone;
  final String line1;
  final String? line2;
  final String? landmark;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  String get formatted =>
      [line1, if (line2 != null && line2!.isNotEmpty) line2, city, state, postalCode]
          .join(', ');

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'line1': line1,
        if (line2 != null && line2!.isNotEmpty) 'line2': line2,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
      };
}
