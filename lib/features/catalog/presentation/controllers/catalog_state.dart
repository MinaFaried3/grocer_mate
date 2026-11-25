import '../../domain/catalog.dart';

const CatalogQuery _defaultQuery = (
  search: '',
  category: null,
  brand: null,
  deals: false,
);

class CatalogState {
  const CatalogState({
    this.query = _defaultQuery,
    this.categories = const [],
    this.brands = const [],
    this.products = const [],
    this.page = 0,
    this.total = 0,
    this.loading = true,
    this.error,
  });

  final CatalogQuery query;
  final List<Category> categories;
  final List<String> brands;
  final List<Product> products;
  final int page;
  final int total;
  final bool loading;
  final String? error;

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
  }) => CatalogState(
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
