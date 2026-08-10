import 'package:equatable/equatable.dart';

/// Сущность пользователя (чистая бизнес-логика)
class User extends Equatable {
  final int id;
  final String phone;
  final String? name;
  final String? email;
  final String? avatar;
  final String? accessToken;
  final String? refreshToken;

  const User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.avatar,
    this.accessToken,
    this.refreshToken,
  });

  @override
  List<Object?> get props => [
        id,
        phone,
        name,
        email,
        avatar,
        accessToken,
        refreshToken,
      ];

  /// Создает копию с обновленными полями
  User copyWith({
    int? id,
    String? phone,
    String? name,
    String? email,
    String? avatar,
    String? accessToken,
    String? refreshToken,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}










