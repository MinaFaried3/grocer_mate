import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/network/connection.dart';

import '../domain/catalog.dart';

const CatalogQuery _defaultQuery = (
  search: '',
  category: null,
  brand: null,
  deals: false,
);

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

  CatalogState _failed(String message) => CatalogState(
    query: query,
    categories: categories,
    brands: brands,
    products: products,
    page: page,
    total: total,
    loading: false,
    error: message,
  );
}

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc(this._repository) : super(const CatalogState()) {
    on<CatalogEvent>(_handle);
  }

  static const pageSize = 8;
  final CatalogRepository _repository;
  Timer? _searchTimer;
  String _input = '';
  int _generation = 0;

  Future<void> _handle(CatalogEvent event, Emitter<CatalogState> emit) async {
    final query = state.query;
    switch (event) {
      case SearchTyped(:final input):
        _searchTimer?.cancel();
        _input = input.trim();
        if (_input != query.search) {
          _searchTimer = Timer(
            const Duration(milliseconds: 400),
            () => add(_SearchSettled(_input)),
          );
        }
      case _SearchSettled(:final input):
        if (input != _input || input == query.search) return;
        await _load((
          search: input,
          category: query.category,
          brand: query.brand,
          deals: query.deals,
        ), emit);
      case CategorySelected(:final id):
        await _load((
          search: _input,
          category: id,
          brand: null,
          deals: query.deals,
        ), emit);
      case BrandSelected(:final name):
        await _load((
          search: _input,
          category: query.category,
          brand: name,
          deals: query.deals,
        ), emit);
      case DealsSelected():
        await _load((
          search: _input,
          category: query.category,
          brand: query.brand,
          deals: !query.deals,
        ), emit);
      case CatalogRefreshed():
        await _load(query, emit, refresh: true);
      case NextPageRequested():
        if (state.loading || !state.hasMore) return;
        await _load(query, emit, page: state.page + 1);
    }
  }

  Future<void> _load(
    CatalogQuery query,
    Emitter<CatalogState> emit, {
    int page = 1,
    bool refresh = false,
  }) async {
    final generation = ++_generation;
    final firstPage = page == 1;
    final loading = CatalogState(
      query: query,
      categories: state.categories,
      brands: query.category == state.query.category ? state.brands : const [],
      products: firstPage ? const [] : state.products,
      page: firstPage ? 0 : state.page,
      total: firstPage ? 0 : state.total,
    );
    emit(loading);

    try {
      final result = await _repository.browse(
        query,
        page: page,
        pageSize: pageSize,
        refresh: refresh,
      );
      if (generation != _generation) return;
      emit(
        CatalogState(
          query: query,
          categories: result.categories,
          brands: result.brands,
          products: firstPage
              ? result.products
              : List.unmodifiable([...loading.products, ...result.products]),
          page: page,
          total: result.total,
          loading: false,
        ),
      );
    } catch (error) {
      if (generation != _generation) return;
      final message = !firstPage
          ? 'We couldn’t load more groceries.'
          : error is OfflineException
          ? 'Connect once to download the catalog.'
          : 'We couldn’t load groceries.';
      emit(loading._failed(message));
    }
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}
