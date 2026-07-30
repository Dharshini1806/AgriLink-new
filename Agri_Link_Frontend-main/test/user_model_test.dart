import 'package:flutter_test/flutter_test.dart';
import 'package:agrilink/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel parsing tests', () {
    test('should parse user correctly when trust_score, latitude, and longitude are numbers', () {
      final json = {
        'id': '108ad742-8a9c-4b9b-861d-eee4bb076b18',
        'name': 'manoj',
        'email': 'sakthimanoj2810@gmail.com',
        'role': 'buyer',
        'phone': null,
        'latitude': 12.9716,
        'longitude': 77.5946,
        'trust_score': 4.5,
        'is_active': true,
        'farm_name': null,
        'farm_desc': null,
        'profile_img': null,
        'created_at': '2026-05-30T07:57:04.832Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '108ad742-8a9c-4b9b-861d-eee4bb076b18');
      expect(user.trustScore, 4.5);
      expect(user.latitude, 12.9716);
      expect(user.longitude, 77.5946);
    });

    test('should parse user correctly when trust_score, latitude, and longitude are strings', () {
      final json = {
        'id': '108ad742-8a9c-4b9b-861d-eee4bb076b18',
        'name': 'manoj',
        'email': 'sakthimanoj2810@gmail.com',
        'role': 'buyer',
        'phone': null,
        'latitude': '12.9716',
        'longitude': '77.5946',
        'trust_score': '0.00',
        'is_active': true,
        'farm_name': null,
        'farm_desc': null,
        'profile_img': null,
        'created_at': '2026-05-30T07:57:04.832Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '108ad742-8a9c-4b9b-861d-eee4bb076b18');
      expect(user.trustScore, 0.0);
      expect(user.latitude, 12.9716);
      expect(user.longitude, 77.5946);
    });

    test('should handle null values for optional coordinates and fallback trust_score', () {
      final json = {
        'id': '108ad742-8a9c-4b9b-861d-eee4bb076b18',
        'name': 'manoj',
        'email': 'sakthimanoj2810@gmail.com',
        'role': 'buyer',
        'phone': null,
        'latitude': null,
        'longitude': null,
        'trust_score': null,
        'is_active': true,
        'farm_name': null,
        'farm_desc': null,
        'profile_img': null,
        'created_at': '2026-05-30T07:57:04.832Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.latitude, isNull);
      expect(user.longitude, isNull);
      expect(user.trustScore, 0.0);
    });
  });
}
