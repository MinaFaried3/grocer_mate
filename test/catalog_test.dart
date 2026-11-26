import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/features/catalog/domain/catalog.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_event.dart';

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
    expect(bloc.state.brands, ['BakeHouse']);
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
    final retried = await finished;
    expect(retried.error, isNull);
    expect(retried.products.map((product) => product.id), ['milk', 'bread']);
    expect(source.requests.map((request) => request.$2), [1, 2, 2]);
    expect(source.requests.map((request) => request.$3), [true, false, false]);
  });
}

class _Source() implements CatalogRepository {
  final requests = <(CatalogQuery, int, bool)>[];
  bool failNextPage = false;

  @override
  Future<CatalogPage> browse(
    CatalogQuery query, {
    required int page,
    required int pageSize,
    bool refresh = false,
  }) async {
    requests.add((query, page, refresh));
    if (query.search == 'milk' && query.category == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (page == 2 && failNextPage) {
      failNextPage = false;
      throw StateError('Temporary failure');
    }
    final bakery = query.category == 'bakery';
    return (
      products: [if (bakery || page == 2) bread else milk],
      total: bakery ? 1 : 2,
      categories: const <Category>[],
      brands: [if (bakery) 'BakeHouse' else 'DairyPure'],
    );
  }

  @override
  Future<Product> detail(String id) async => milk;
}
