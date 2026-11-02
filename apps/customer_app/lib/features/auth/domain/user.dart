/// Authenticated user profile, mirrors the backend's sanitized user object
/// (`auth.service.js#sanitizeUser`) plus roles from `/auth/me`.
class User {
  const User({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.referralCode,
    this.roles = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isEmailVerified: json['is_email_verified'] as bool? ?? false,
        isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
        referralCode: json['referral_code'] as String?,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? referralCode;
  final List<String> roles;

  bool get isVendor => roles.contains('vendor');

  User copyWith({
    String? fullName,
    String? avatarUrl,
  }) =>
      User(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isEmailVerified: isEmailVerified,
        isPhoneVerified: isPhoneVerified,
        referralCode: referralCode,
        roles: roles,
      );
}
