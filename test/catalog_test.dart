import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/domain/catalog.dart';
import 'package:grocer_mate/presentation/catalog/catalog_bloc.dart';

import 'fixtures.dart';

void main() {
  test('debounces search and discards a late previous query', () async {
    final source = _Source();
    final bloc = CatalogBloc(source);
    addTearDown(bloc.close);

    bloc.add(const SearchTyped('mi'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final loading = bloc.stream.firstWhere(
      (state) => state.loading && state.query.search == 'milk',
    );
    bloc.add(const SearchTyped('milk'));
    await loading;
    final filtered = bloc.stream.firstWhere(
      (state) => !state.loading && state.query.category == 'bakery',
    );
    bloc.add(const CategorySelected('bakery'));
    await filtered;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(source.requests.map((request) => request.$1.search), [
      'milk',
      'milk',
    ]);
    expect(bloc.state.products.single.id, 'bread');
  });

  test('preserves page one when page two fails, then safely retries', () async {
    final source = _Source()..failNextPage = true;
    final bloc = CatalogBloc(source);
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere(
      (state) => state.page == 1 && !state.loading,
    );
    bloc.add(const CatalogRefreshed());
    await loaded;
    final failed = bloc.stream.firstWhere((state) => state.error != null);
    bloc.add(const NextPageRequested());
    expect((await failed).products.single.id, 'milk');

    final finished = bloc.stream.firstWhere(
      (state) => state.page == 2 && !state.loading,
    );
    bloc.add(const NextPageRequested());
    expect((await finished).products.map((product) => product.id), [
      'milk',
      'bread',
    ]);
    expect(source.requests.map((request) => request.$2), [1, 2, 2]);
  });
}

class _Source implements CatalogRepository {
  final requests = <(CatalogQuery, int)>[];
  bool failNextPage = false;

  @override
  Future<CatalogPage> browse(
    CatalogQuery query, {
    required int page,
    required int pageSize,
  }) async {
    requests.add((query, page));
    if (query.search == 'milk' && query.category == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (query.category == 'bakery') return (products: [bread], total: 1);
    if (page == 2) {
      if (failNextPage) {
        failNextPage = false;
        throw StateError('Temporary failure');
      }
      return (products: [bread], total: 2);
    }
    return (products: [milk], total: 2);
  }

  @override
  Future<CatalogFilters> filters(String? category) async =>
      (categories: <Category>[], brands: <String>[]);

  @override
  Future<Product> detail(String id) async => milk;
}
