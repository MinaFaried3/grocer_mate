class Category {
  const Category({required this.id, required this.name, required this.icon});
  final String id;
  final String name;
  final String icon;

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'], name: json['name'], icon: json['icon']);
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.brand,
    required this.categoryId,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.rating,
    required this.description,
    required this.images,
    required this.badges,
    required this.nutrition,
    required this.allergens,
  });

  final String id;
  final String title;
  final String brand;
  final String categoryId;
  final int price;
  final int originalPrice;
  final int stock;
  final double rating;
  final String description;
  final List<String> images;
  final List<String> badges;
  final Map<String, num> nutrition;
  final List<String> allergens;

  int get discountPercent => originalPrice > price
      ? ((originalPrice - price) * 100 / originalPrice).round()
      : 0;

  Product withAvailability({required int price, required int stock}) => Product(
    id: id,
    title: title,
    brand: brand,
    categoryId: categoryId,
    price: price,
    originalPrice: originalPrice,
    stock: stock,
    rating: rating,
    description: description,
    images: images,
    badges: badges,
    nutrition: nutrition,
    allergens: allergens,
  );

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    title: json['title'],
    brand: json['brand'],
    categoryId: json['categoryId'],
    price: json['price'],
    originalPrice: json['originalPrice'],
    stock: json['stock'],
    rating: (json['rating'] as num).toDouble(),
    description: json['description'],
    images: List<String>.unmodifiable(json['images']),
    badges: List<String>.unmodifiable(json['badges']),
    nutrition: Map<String, num>.unmodifiable(json['nutrition'] ?? {}),
    allergens: List<String>.unmodifiable(json['allergens'] ?? []),
  );

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'brand': brand,
    'categoryId': categoryId,
    'price': price,
    'originalPrice': originalPrice,
    'stock': stock,
    'rating': rating,
    'description': description,
    'images': images,
    'badges': badges,
    'nutrition': nutrition,
    'allergens': allergens,
  };
}

typedef CatalogQuery = ({
  String search,
  String? category,
  String? brand,
  bool deals,
});
typedef CatalogPage = ({
  List<Product> products,
  int total,
  List<Category> categories,
  List<String> brands,
});

abstract interface class CatalogRepository {
  Future<CatalogPage> browse(
    CatalogQuery query, {
    required int page,
    required int pageSize,
    bool refresh = false,
  });
  Future<Product> detail(String id);
}
