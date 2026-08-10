class LoginRequest {
  final String phone;
  final String code;

  LoginRequest({required this.phone, required this.code});

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phone,
      'code': code,
    };
  }
}


