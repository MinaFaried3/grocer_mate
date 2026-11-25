import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/catalog.dart';
import '../../domain/shopping.dart';

const _defaultQuery = (search: '', category: null, brand: null, deals: false);

sealed class CatalogEvent {
  const CatalogEvent();
}

class SearchTyped extends CatalogEvent {
  const SearchTyped(this.input);
  final String input;
}

class CategorySelected extends CatalogEvent {
  const CategorySelected(this.id);
  final String? id;
}

class BrandSelected extends CatalogEvent {
  const BrandSelected(this.name);
  final String? name;
}

class DealsSelected extends CatalogEvent {
  const DealsSelected();
}

class CatalogRefreshed extends CatalogEvent {
  const CatalogRefreshed();
}

class NextPageRequested extends CatalogEvent {
  const NextPageRequested();
}

class _SearchSettled extends CatalogEvent {
  const _SearchSettled(this.input);
  final String input;
}

typedef CatalogState = ({
  CatalogQuery query,
  List<Category> categories,
  List<String> brands,
  List<Product> products,
  int page,
  int total,
  bool loading,
  String? error,
});

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc(this._repository)
    : super((
        query: _defaultQuery,
        categories: [],
        brands: [],
        products: [],
        page: 0,
        total: 0,
        loading: true,
        error: null,
      )) {
    on<SearchTyped>((event, emit) {
      _searchTimer?.cancel();
      _input = event.input.trim();
      if (_input != state.query.search) {
        _searchTimer = Timer(
          const Duration(milliseconds: 400),
          () => add(_SearchSettled(_input)),
        );
      }
    });
    on<_SearchSettled>((event, emit) async {
      if (event.input == _input && event.input != state.query.search) {
        final current = state.query;
        await _reload((
          search: event.input,
          category: current.category,
          brand: current.brand,
          deals: current.deals,
        ), emit);
      }
    });
    on<CategorySelected>(
      (event, emit) => _reload((
        search: _input,
        category: event.id,
        brand: null,
        deals: state.query.deals,
      ), emit),
    );
    on<BrandSelected>(
      (event, emit) => _reload((
        search: _input,
        category: state.query.category,
        brand: event.name,
        deals: state.query.deals,
      ), emit),
    );
    on<DealsSelected>(
      (event, emit) => _reload((
        search: _input,
        category: state.query.category,
        brand: state.query.brand,
        deals: !state.query.deals,
      ), emit),
    );
    on<CatalogRefreshed>((event, emit) => _reload(state.query, emit));
    on<NextPageRequested>(_nextPage);
  }

  static const pageSize = 8;
  final CatalogRepository _repository;
  Timer? _searchTimer;
  String _input = '';
  int _generation = 0;

  Future<void> _reload(CatalogQuery query, Emitter<CatalogState> emit) async {
    final generation = ++_generation;
    emit((
      query: query,
      categories: state.categories,
      brands: query.category == state.query.category ? state.brands : const [],
      products: const [],
      page: 0,
      total: 0,
      loading: true,
      error: null,
    ));
    try {
      final (filters, page) = await (
        _repository.filters(query.category),
        _repository.browse(query, page: 1, pageSize: pageSize),
      ).wait;
      if (_generation != generation) return;
      emit((
        query: query,
        categories: filters.categories,
        brands: filters.brands,
        products: page.products,
        page: 1,
        total: page.total,
        loading: false,
        error: null,
      ));
    } on ParallelWaitError catch (error) {
      if (_generation != generation) return;
      final offline =
          error.errors.$1?.error is OfflineException ||
          error.errors.$2?.error is OfflineException;
      emit((
        query: query,
        categories: state.categories,
        brands: state.brands,
        products: const [],
        page: 0,
        total: 0,
        loading: false,
        error: offline
            ? 'Connect once to download the catalog.'
            : 'We couldn’t load groceries.',
      ));
    }
  }

  Future<void> _nextPage(
    NextPageRequested event,
    Emitter<CatalogState> emit,
  ) async {
    final previous = state;
    if (previous.loading || previous.products.length >= previous.total) return;
    final generation = _generation;
    emit((
      query: previous.query,
      categories: previous.categories,
      brands: previous.brands,
      products: previous.products,
      page: previous.page,
      total: previous.total,
      loading: true,
      error: null,
    ));
    try {
      final result = await _repository.browse(
        previous.query,
        page: previous.page + 1,
        pageSize: pageSize,
      );
      if (_generation != generation) return;
      final byId = {
        for (final product in previous.products) product.id: product,
        for (final product in result.products) product.id: product,
      };
      emit((
        query: previous.query,
        categories: previous.categories,
        brands: previous.brands,
        products: List.unmodifiable(byId.values),
        page: previous.page + 1,
        total: result.total,
        loading: false,
        error: null,
      ));
    } catch (_) {
      if (_generation != generation) return;
      emit((
        query: previous.query,
        categories: previous.categories,
        brands: previous.brands,
        products: previous.products,
        page: previous.page,
        total: previous.total,
        loading: false,
        error: 'We couldn’t load more groceries.',
      ));
    }
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}
