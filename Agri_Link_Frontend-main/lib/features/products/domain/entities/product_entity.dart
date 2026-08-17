import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String sellerId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String? quantityUnit;
  final String? qualityGrade;
  final String? deliveryArea;
  final double deliveryRadiusKm;
  final List<String> imageUrls;
  final bool isActive;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined fields from API
  final String? categoryName;
  final String? categoryIcon;
  final String? sellerName;
  final String? sellerPhone;
  final double? sellerTrust;
  final String? farmName;
  final String? farmDesc;
  final double? sellerLat;
  final double? sellerLng;
  final double avgRating;
  final int reviewCount;
  final double? distanceKm;

  // Recommendation / sell-performance fields
  final double? sellPct;      // % of seller's total sales this product accounts for
  final double? sellerScore;  // composite seller performance score (for feed ordering)
  final int? qtySold;         // total units of this product delivered
  final int? likesCount;      // total people who liked the product based on feedback

  const ProductEntity({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.quantityUnit = 'kg',
    this.qualityGrade,
    this.deliveryArea,
    this.deliveryRadiusKm = 30.0,
    this.imageUrls = const [],
    this.isActive = true,
    this.isApproved = true,
    required this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.categoryIcon,
    this.sellerName,
    this.sellerPhone,
    this.sellerTrust,
    this.farmName,
    this.farmDesc,
    this.sellerLat,
    this.sellerLng,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.distanceKm,
    this.sellPct,
    this.sellerScore,
    this.qtySold,
    this.likesCount,
  });

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'seller_id':
        return sellerId;
      case 'category_id':
        return categoryId;
      case 'name':
        return name;
      case 'description':
        return description;
      case 'price':
        return price;
      case 'quantity':
        return quantity;
      case 'quantity_unit':
        return quantityUnit;
      case 'quality_grade':
        return qualityGrade;
      case 'delivery_area':
        return deliveryArea;
      case 'delivery_radius_km':
        return deliveryRadiusKm;
      case 'image_urls':
        return imageUrls;
      case 'is_active':
        return isActive;
      case 'is_approved':
        return isApproved;
      case 'created_at':
        return createdAt.toIso8601String();
      case 'updated_at':
        return updatedAt?.toIso8601String();
      case 'category_name':
        return categoryName;
      case 'category_icon':
        return categoryIcon;
      case 'seller_name':
        return sellerName;
      case 'seller_phone':
        return sellerPhone;
      case 'seller_trust':
        return sellerTrust;
      case 'farm_name':
        return farmName;
      case 'farm_desc':
        return farmDesc;
      case 'seller_lat':
        return sellerLat;
      case 'seller_lng':
        return sellerLng;
      case 'avg_rating':
        return avgRating;
      case 'review_count':
        return reviewCount;
      case 'distance_km':
        return distanceKm;
      case 'sell_pct':
        return sellPct;
      case 'seller_score':
        return sellerScore;
      case 'qty_sold':
        return qtySold;
      case 'likes_count':
        return likesCount;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        categoryId,
        name,
        price,
        quantity,
        quantityUnit,
        isActive,
        isApproved,
        createdAt,
        sellPct,
        sellerScore,
        qtySold,
        likesCount,
      ];
}
