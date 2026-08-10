class SendCodeRequest {
  final String phone;

  SendCodeRequest({required this.phone});

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phone,
    };
  }
}


