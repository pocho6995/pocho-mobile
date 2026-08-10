class CheckRegistrationRequest {
  final String phone;

  CheckRegistrationRequest({required this.phone});

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phone,
    };
  }
}


