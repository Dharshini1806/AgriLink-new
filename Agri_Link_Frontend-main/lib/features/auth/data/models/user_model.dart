import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.latitude,
    super.longitude,
    super.trustScore,
    super.isActive,
    super.farmName,
    super.farmDesc,
    super.profileImg,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:          json['id'] as String,
    name:        json['name'] as String,
    email:       json['email'] as String,
    role:        json['role'] as String,
    phone:       json['phone'] as String?,
    latitude:    _toDouble(json['latitude']),
    longitude:   _toDouble(json['longitude']),
    trustScore:  _toDouble(json['trust_score']) ?? 0.0,
    isActive:    json['is_active'] as bool? ?? true,
    farmName:    json['farm_name'] as String?,
    farmDesc:    json['farm_desc'] as String?,
    profileImg:  json['profile_img'] as String?,
    createdAt:   DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'role': role,
    'phone': phone, 'latitude': latitude, 'longitude': longitude,
    'trust_score': trustScore, 'is_active': isActive,
    'farm_name': farmName, 'farm_desc': farmDesc,
    'profile_img': profileImg, 'created_at': createdAt.toIso8601String(),
  };

  UserModel copyWith({
    String? name, String? phone, double? latitude, double? longitude,
    String? farmName, String? farmDesc, String? profileImg,
  }) => UserModel(
    id: id, email: email, role: role, createdAt: createdAt,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    trustScore: trustScore, isActive: isActive,
    farmName: farmName ?? this.farmName,
    farmDesc: farmDesc ?? this.farmDesc,
    profileImg: profileImg ?? this.profileImg,
  );
}

double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString());
}
