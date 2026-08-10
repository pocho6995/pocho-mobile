class LoginResponse {
  final String accessToken;
  final String tokenType;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw FormatException('access_token is missing or empty in response');
    }
    return LoginResponse(
      accessToken: accessToken,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }
}


