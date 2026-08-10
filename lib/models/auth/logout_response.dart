class LogoutResponse {
  final bool success;
  final String? message;

  LogoutResponse({
    required this.success,
    this.message,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}












