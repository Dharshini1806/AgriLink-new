import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? iconUrl;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'icon_url':
        return iconUrl;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [id, name, iconUrl];
}
