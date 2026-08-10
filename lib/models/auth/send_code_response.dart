class SendCodeResponse {
  final String? message;
  final String? phoneNumber;
  final int? expiresIn;

  SendCodeResponse({
    this.message,
    this.phoneNumber,
    this.expiresIn,
  });

  factory SendCodeResponse.fromJson(Map<String, dynamic> json) {
    return SendCodeResponse(
      message: json['message'] as String?,
      phoneNumber: json['phone_number'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }
}


