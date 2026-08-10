import 'profile_documents.dart';
import 'profile_settings.dart';

class UserProfileResponse {
  final UserData user;
  final ProfileData profile;

  UserProfileResponse({
    required this.user,
    required this.profile,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    // Данные пользователя находятся на верхнем уровне JSON
    // Профиль находится в поле 'profile'
    final profileJson = json['profile'] as Map<String, dynamic>?;
    if (profileJson == null) {
      throw FormatException('Profile data is missing in response');
    }
    
    return UserProfileResponse(
      user: UserData.fromJson(json),
      profile: ProfileData.fromJson(profileJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'profile': profile.toJson(),
    };
  }
}

class UserData {
  final int id;
  final String phone;
  final String name;
  final String? email;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String language;
  final double balance;
  final String level;
  final double rating;
  final int totalStationsVisited;
  final double totalSpent;

  UserData({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
    required this.language,
    required this.balance,
    required this.level,
    required this.rating,
    required this.totalStationsVisited,
    required this.totalSpent,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    // Безопасный парсинг дат
    DateTime parseDateTime(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return UserData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      language: json['language'] as String? ?? 'ru',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      level: json['level'] as String? ?? 'Новичок',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalStationsVisited: (json['total_stations_visited'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'language': language,
      'balance': balance,
      'level': level,
      'rating': rating,
      'total_stations_visited': totalStationsVisited,
      'total_spent': totalSpent,
    };
  }
}

class ProfileData {
  final int id;
  final int userId;
  final ProfileDocuments documents;
  final ProfileSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileData({
    required this.id,
    required this.userId,
    required this.documents,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    // Безопасный парсинг дат
    DateTime parseDateTime(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    final documentsJson = json['documents'] as Map<String, dynamic>?;
    final settingsJson = json['settings'] as Map<String, dynamic>?;
    
    if (documentsJson == null) {
      throw FormatException('Documents data is missing in profile');
    }
    if (settingsJson == null) {
      throw FormatException('Settings data is missing in profile');
    }
    
    return ProfileData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      documents: ProfileDocuments.fromJson(documentsJson),
      settings: ProfileSettings.fromJson(settingsJson),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'documents': documents.toJson(),
      'settings': settings.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

