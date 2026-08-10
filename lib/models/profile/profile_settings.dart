class ProfileSettings {
  final bool notificationsEnabled;
  final String language;

  ProfileSettings({
    required this.notificationsEnabled,
    required this.language,
  });

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    return ProfileSettings(
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'ru',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'language': language,
    };
  }
}












