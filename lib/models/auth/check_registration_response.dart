class CheckRegistrationResponse {
  final bool isRegistered;

  CheckRegistrationResponse({required this.isRegistered});

  factory CheckRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return CheckRegistrationResponse(
      isRegistered: json['is_registered'] as bool? ?? false,
    );
  }
}













