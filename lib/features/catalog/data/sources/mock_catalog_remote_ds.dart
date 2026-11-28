import 'package:grocer_mate/core/network/endpoint_exception.dart';
import 'package:grocer_mate/core/network/endpoints.dart';
import 'package:grocer_mate/core/network/page_response.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:grocer_mate/core/storage/mock_json_reader.dart';

import '../../domain/entities/catalog.dart';
import '../models/deals_response.dart';
import '../models/product_response.dart';
import 'catalog_remote_source.dart';

class MockCatalogRemoteDS with MockJsonReader implements CatalogRemoteSource {
  MockCatalogRemoteDS(this.loadMockAsset, this._readAvailability);

  @override
  final Future<String> Function(String) loadMockAsset;
  final Future<Map> Function() _readAvailability;

  //------------ Catalog Remote Source ---------------
  @override
  Future<List<Category>> categories() async => [
    for (final item in await categoriesPayload())
      Category.fromJson(item as Json),
  ];

  @override
  Future<List<String>> brands(String? category) async {
    final json = await brandsPayload(category);
    final groups = category == null ? json.values : [json[category]];
    return {
      for (final names in groups)
        if (names is List) ...names.cast<String>(),
    }.toList()..sort();
  }

  @override
  Future<({List<Product> products, int total})> products(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  }) async {
    final json = await productsPayload(
      category: query.category,
      brand: query.brand,
      search: query.search,
      page: page,
      pageSize: pageSize,
    );
    final response = PageResponse<ProductResponse>.fromJson(
      json,
      (item) => ProductResponse.fromJson(item as Json),
    );
    return (
      products: [for (final item in response.data) item.toProduct()],
      total: response.total,
    );
  }

  @override
  Future<Product> detail(String id, {Product? summary}) async =>
      ProductResponse.fromJson(await productPayload(id))
          .toProduct(summary: summary);

  @override
  Future<DealsResponse> dealsOfDay() async =>
      DealsResponse.fromJson(await dealsOfDayPayload());

  //------------ Shared Product Availability ---------------
  Future<List<Json>> productsWithAvailability(Map availability) async {
    final seed = (await readMockJson<List>(Endpoints.products)).cast<Json>();
    return [
      for (final product in seed)
        _withAvailability(
          product,
          availability[product['id']] as Map? ?? const {},
        ),
    ];
  }

  Json _withAvailability(Json product, Map changes) => {
    ...product,
    if (changes['price'] case final int cents) 'price': cents / 100,
    if (changes['stock'] case final int stock) 'stock': stock,
  };

  //------------ Mock API Payloads ---------------
  Future<List<dynamic>> categoriesPayload() =>
      readMockJson<List<dynamic>>(Endpoints.categories);

  Future<Json> brandsPayload([String? category]) async {
    final brands = await readMockJson<Json>(Endpoints.brands);
    final id = category?.trim().toLowerCase();
    return id == null || id.isEmpty ? brands : {id: brands[id] ?? <String>[]};
  }

  Future<Json> productsPayload({
    String? category,
    String? brand,
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    //------------ Validate and Normalize the Query ---------------
    if (page < 1 || pageSize < 1) {
      throw const FormatException('Expected positive pagination values.');
    }
    final categoryId = category?.trim().toLowerCase() ?? '';
    final brandName = brand?.trim().toLowerCase() ?? '';
    final words = (search?.trim().toLowerCase() ?? '').split(RegExp(r'\s+'));

    //------------ Filter Products Before Paging ---------------
    final products = await productsWithAvailability(await _readAvailability());
    final matching = products.where((product) {
      // Check category, brand, and search query filters for each product.
      final matchesCategory =
          categoryId.isEmpty || product['categoryId'] == categoryId;
      final matchesBrand =
          brandName.isEmpty ||
          (product['brand'] as String).toLowerCase() == brandName;
      final matchesSearch = words.every(
        (product['title'] as String).toLowerCase().contains,
      );
      return matchesCategory && matchesBrand && matchesSearch;
    }).toList();

    //------------ Build the Requested Page ---------------
    return {
      'data': page - 1 > matching.length ~/ pageSize
          ? <Json>[]
          : matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      'page': page,
      'pageSize': pageSize,
      'total': matching.length,
      'sort': 'popularity_desc',
    };
  }

  Future<Json> productPayload(String id) => _productData(Endpoints.product, id);
  Future<Json> inventory(String id) => _productData(Endpoints.inventory, id);
  Future<Json> priceHistory(String id) =>
      _productData(Endpoints.priceHistory, id);
  Future<Json> dealsOfDayPayload() async =>
      dealsWithAvailability(await _readAvailability());

  Future<Json> suggestions(String? input) async {
    final q = input?.trim().toLowerCase() ?? '';
    final words = await readMockJson<List>(Endpoints.suggest);
    final products = await productsWithAvailability(await _readAvailability());
    final candidates = {
      ...words.cast<String>(),
      for (final product in products)
        (product['title'] as String).split(' (').first.toLowerCase(),
    };
    return {
      'q': q,
      'suggestions': q.isEmpty
          ? <String>[]
          : candidates.where((text) => text.startsWith(q)).take(8).toList(),
    };
  }

  Future<Json> checkStock(String? input) async {
    final seed = await readMockJson<Json>(Endpoints.stockCheck);
    final ids =
        (input?.split(',') ?? (seed['defaultIds'] as List).cast<String>())
            .map((id) => id.trim().toLowerCase())
            .toSet();
    final byId = {
      for (final product in await productsWithAvailability(
        await _readAvailability(),
      ))
        product['id']: product,
    };
    return {
      'stocks': [
        for (final id in ids)
          if (byId[id] case final product?)
            {'productId': id, 'stock': product['stock']},
      ],
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Json> _productData(String kind, String id) async {
    //------------ Find the Product and Load Mock Data ---------------
    final key = id.toLowerCase();
    final products = await productsWithAvailability(await _readAvailability());
    final product = products.where((item) => item['id'] == key).firstOrNull;
    if (product == null) {
      throw const EndpointException(404, 'Product not found.');
    }
    final mock = await readMockJson<Json>(kind);

    //------------ Build Product or Inventory Details ---------------
    if (kind == Endpoints.product) {
      return {...product, ...?(mock[key] as Json?)}..remove('image');
    }
    if (kind == Endpoints.inventory) {
      return {
        ...mock['default'] as Json,
        ...?(mock[key] as Json?),
        'productId': key,
        'stock': product['stock'],
      };
    }

    //------------ Append the Current Price to History ---------------
    final history = (mock[key] as List?) ?? [product['originalPrice']];
    return {
      'productId': key,
      'history': [
        ...history,
        if (history.lastOrNull != product['price']) product['price'],
      ],
    };
  }

  //------------ Daily Offers with Current Prices ---------------
  Future<Json> dealsWithAvailability(Map availability) async {
    final flags = await readMockJson<Json>(Endpoints.flags);
    final data = await readMockJson<Json>(Endpoints.dealsOfDay);
    final now = DateTime.now().toUtc();
    final date = now.toIso8601String().split('T').first;
    return {
      'date': date,
      'items': [
        if (flags['showDeals'] == true)
          for (final item in (data['items'] as List).cast<Json>())
            {
              ...item,
              if ((availability[item['productId']] as Map?)?['price']
                  case final int cents)
                'dealPrice': cents / 100,
              'endsAt': '${date}T${(item['endsAt'] as String).split('T').last}',
            },
      ],
    };
  }
}
