class Category {
  const Category({required this.id, required this.name, required this.icon});
  final String id;
  final String name;
  final String icon;
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
  }) : assert(price >= 0),
       assert(originalPrice >= 0),
       assert(stock >= 0),
       assert(rating >= 0 && rating <= 5);

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
