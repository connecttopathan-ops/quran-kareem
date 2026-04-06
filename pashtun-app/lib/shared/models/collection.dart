import 'product.dart';

class Collection {
  final String id;
  final String handle;
  final String title;
  final String? description;
  final ProductImage? image;

  const Collection({
    required this.id,
    required this.handle,
    required this.title,
    this.description,
    this.image,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json['id'] as String,
    handle: json['handle'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    image: json['image'] != null
        ? ProductImage.fromJson(json['image'] as Map<String, dynamic>)
        : null,
  );
}
