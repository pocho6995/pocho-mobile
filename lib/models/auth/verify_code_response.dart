class VerifyCodeResponse {
  final String accessToken;
  final String tokenType;
  final bool isVerified;
  final String? message;

  VerifyCodeResponse({
    required this.accessToken,
    required this.tokenType,
    required this.isVerified,
    this.message,
  });

  factory VerifyCodeResponse.fromJson(Map<String, dynamic> json) {
    // Токен может быть на верхнем уровне или внутри объекта "token"
    Map<String, dynamic>? tokenData;
    
    if (json.containsKey('token') && json['token'] is Map<String, dynamic>) {
      // Токен внутри объекта "token"
      tokenData = json['token'] as Map<String, dynamic>;
    } else if (json.containsKey('access_token')) {
      // Токен на верхнем уровне
      tokenData = json;
    } else {
      throw FormatException('access_token is missing in response');
    }

    final accessToken = tokenData['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw FormatException('access_token is missing or empty in response');
    }

    return VerifyCodeResponse(
      accessToken: accessToken,
      tokenType: tokenData['token_type'] as String? ?? 'bearer',
      isVerified: json['is_verified'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}


