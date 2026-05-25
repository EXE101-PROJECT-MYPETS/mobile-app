import 'package:image_picker/image_picker.dart';
import 'package:petpee_mobile/common/user/model/user_model.dart';

typedef User = UserModel;

class AuthenticationRequest {
  const AuthenticationRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.province,
    required this.district,
    required this.ward,
    required this.hamlet,
    this.age,
    this.avatarUrlPreview,
  });

  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String address;
  final String province;
  final String district;
  final String ward;
  final String hamlet;
  final int? age;
  final XFile? avatarUrlPreview;

  Map<String, String> toMultipartFields() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'province': province,
      'district': district,
      'ward': ward,
      'hamlet': hamlet,
      if (age != null) 'age': age.toString(),
    };
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.email,
    required this.fullName,
    required this.phone,
    this.age,
    this.avatarUrlPreview,
  });

  final String email;
  final String fullName;
  final String phone;
  final int? age;
  final XFile? avatarUrlPreview;

  Map<String, String> toMultipartFields() {
    final fields = {'email': email, 'fullName': fullName, 'phone': phone};
    if (age != null) fields['age'] = age.toString();
    return fields;
  }
}

class RegisterEmailVerificationSendRequest {
  const RegisterEmailVerificationSendRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class RegisterEmailVerificationVerifyRequest {
  const RegisterEmailVerificationVerifyRequest({
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code};
  }
}

class EmailVerificationResponse {
  const EmailVerificationResponse({
    required this.success,
    required this.email,
    required this.purpose,
    required this.message,
  });

  final bool success;
  final String email;
  final String purpose;
  final String message;

  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) {
    return EmailVerificationResponse(
      success: json['success'] as bool? ?? false,
      email: json['email'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class AuthShopDTO {
  const AuthShopDTO({
    required this.id,
    required this.name,
    required this.addressText,
    required this.shopStatus,
    required this.memberRole,
    required this.memberStatus,
  });

  final int id;
  final String name;
  final String addressText;
  final String shopStatus;
  final String memberRole;
  final String memberStatus;

  factory AuthShopDTO.fromJson(Map<String, dynamic> json) {
    return AuthShopDTO(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      addressText: json['addressText'] as String? ?? '',
      shopStatus: json['shopStatus'] as String? ?? '',
      memberRole: json['memberRole'] as String? ?? '',
      memberStatus: json['memberStatus'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'addressText': addressText,
      'shopStatus': shopStatus,
      'memberRole': memberRole,
      'memberStatus': memberStatus,
    };
  }
}

class UserLoginResponse {
  const UserLoginResponse({
    required this.accessToken,
    required this.role,
    required this.refreshToken,
    required this.user,
    required this.shops,
    required this.currentShopId,
  });

  final String accessToken;
  final String role;
  final String refreshToken;
  final User user;
  final List<AuthShopDTO> shops;
  final int? currentShopId;

  factory UserLoginResponse.fromJson(Map<String, dynamic> json) {
    return UserLoginResponse(
      accessToken: json['accessToken'] as String? ?? '',
      role: json['role'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      shops: (json['shops'] as List<dynamic>? ?? const [])
          .map((item) => AuthShopDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentShopId: (json['currentShopId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'role': role,
      'refreshToken': refreshToken,
      'user': user.toJson(),
      'shops': shops.map((shop) => shop.toJson()).toList(),
      'currentShopId': currentShopId,
    };
  }
}

typedef AuthenticationResponse = UserLoginResponse;

class TokenRefresh {
  const TokenRefresh({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String role;
  final User user;

  factory TokenRefresh.fromJson(Map<String, dynamic> json) {
    return TokenRefresh(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      role: json['role'] as String? ?? '',
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}

// ── Forgot Password DTOs ────────────────────────────────────────────

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class VerifyOtpForgotPasswordRequest {
  const VerifyOtpForgotPasswordRequest({
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  Map<String, dynamic> toJson() {
    return {'email': email, 'otp': otp};
  }
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {'email': email, 'otp': otp, 'newPassword': newPassword};
  }
}

class ForgotPasswordResponse {
  const ForgotPasswordResponse({
    required this.message,
    required this.email,
    required this.expiresInSeconds,
  });

  final String message;
  final String email;
  final int expiresInSeconds;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      message: json['message'] as String? ?? '',
      email: json['email'] as String? ?? '',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 600,
    );
  }
}

class GoogleLoginRequest {
  const GoogleLoginRequest({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() {
    return {'idToken': idToken};
  }
}

class FacebookLoginRequest {
  const FacebookLoginRequest({required this.accessToken});

  final String accessToken;

  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken};
  }
}
