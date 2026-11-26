import '../../domain/catalog.dart';

const CatalogQuery _defaultQuery = (
  search: '',
  category: null,
  brand: null,
  deals: false,
);

class const CatalogState({
  final CatalogQuery query = _defaultQuery,
  final List<Category> categories = const [],
  final List<String> brands = const [],
  final List<Product> products = const [],
  final int page = 0,
  final int total = 0,
  final bool loading = true,
  final String? error,
}) {
  bool get hasMore => products.length < total;

  CatalogState copyWith({
    CatalogQuery? query,
    List<Category>? categories,
    List<String>? brands,
    List<Product>? products,
    int? page,
    int? total,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => .new(
    query: query ?? this.query,
    categories: categories ?? this.categories,
    brands: brands ?? this.brands,
    products: products ?? this.products,
    page: page ?? this.page,
    total: total ?? this.total,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}
