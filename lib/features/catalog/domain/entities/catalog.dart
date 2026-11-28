class const Category({
  required final String id,
  required final String name,
  required final String icon,
});

class const Product({
  required final String id,
  required final String title,
  required final String brand,
  required final String categoryId,
  required final int price,
  required final int originalPrice,
  required final int stock,
  required final double rating,
  required final String description,
  required final List<String> images,
  required final List<String> badges,
  required final Map<String, num> nutrition,
  required final List<String> allergens,
  final List<String> related = const [],
}) {
  this
    : assert(price >= 0),
      assert(originalPrice >= 0),
      assert(stock >= 0),
      assert(rating >= 0 && rating <= 5);

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
