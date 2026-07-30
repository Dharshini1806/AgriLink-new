// ═══════════════════════════════════════════════════════════════
// DOMAIN LAYER: entities/user_entity.dart
// ═══════════════════════════════════════════════════════════════
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double trustScore;
  final bool isActive;
  final String? farmName;
  final String? farmDesc;
  final String? profileImg;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.latitude,
    this.longitude,
    this.trustScore = 0,
    this.isActive = true,
    this.farmName,
    this.farmDesc,
    this.profileImg,
    required this.createdAt,
  });

  bool get isBuyer  => role == 'buyer';
  bool get isSeller => role == 'seller';
  bool get isAdmin  => role == 'admin';

  bool get hasEnoughReviews => trustScore > 0;

  @override
  List<Object?> get props => [id, email, role];
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final UserEntity user;
  const AuthTokens({required this.accessToken, required this.refreshToken, required this.user});
}
