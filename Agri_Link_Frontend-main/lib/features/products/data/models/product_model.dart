import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.sellerId,
    required super.categoryId,
    required super.name,
    super.description,
    required super.price,
    required super.quantity,
    super.quantityUnit,
    super.qualityGrade,
    super.deliveryArea,
    super.deliveryRadiusKm,
    super.imageUrls,
    super.isActive,
    super.isApproved,
    required super.createdAt,
    super.updatedAt,
    super.categoryName,
    super.categoryIcon,
    super.sellerName,
    super.sellerPhone,
    super.sellerTrust,
    super.farmName,
    super.farmDesc,
    super.sellerLat,
    super.sellerLng,
    super.avgRating,
    super.reviewCount,
    super.distanceKm,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      price: _toDouble(json['price']) ?? 0.0,
      quantity: json['quantity'] as int? ?? 0,
      quantityUnit: json['quantity_unit'] as String? ?? 'kg',
      qualityGrade: json['quality_grade'] as String?,
      deliveryArea: json['delivery_area'] as String?,
      deliveryRadiusKm: _toDouble(json['delivery_radius_km']) ?? 30.0,
      imageUrls: (json['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['is_active'] as bool? ?? true,
      isApproved: json['is_approved'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      sellerName: json['seller_name'] as String?,
      sellerPhone: json['seller_phone'] as String?,
      sellerTrust: _toDouble(json['seller_trust']),
      farmName: json['farm_name'] as String?,
      farmDesc: json['farm_desc'] as String?,
      sellerLat: _toDouble(json['seller_lat']),
      sellerLng: _toDouble(json['seller_lng']),
      avgRating: _toDouble(json['avg_rating']) ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      distanceKm: _toDouble(json['distance_km']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'quantity_unit': quantityUnit,
        'quality_grade': qualityGrade,
        'delivery_area': deliveryArea,
        'delivery_radius_km': deliveryRadiusKm,
        'image_urls': imageUrls,
        'is_active': isActive,
        'is_approved': isApproved,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'category_name': categoryName,
        'category_icon': categoryIcon,
        'seller_name': sellerName,
        'seller_phone': sellerPhone,
        'seller_trust': sellerTrust,
        'farm_name': farmName,
        'farm_desc': farmDesc,
        'seller_lat': sellerLat,
        'seller_lng': sellerLng,
        'avg_rating': avgRating,
        'review_count': reviewCount,
        'distance_km': distanceKm,
      };
}

double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString());
}
