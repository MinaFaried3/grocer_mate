import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/network/connection.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/repositories/catalog_repository.dart';

sealed class ProductDetailState {
  const ProductDetailState();
}

class const ProductDetailLoading() extends ProductDetailState;

class const ProductDetailLoaded(final Product product)
    extends ProductDetailState;

class const ProductDetailFailed(final String message)
    extends ProductDetailState;

class ProductDetailController(
  final CatalogRepository _repository,
  final String _id,
) extends Cubit<ProductDetailState> {
  this : super(const ProductDetailLoading());

  bool _loading = false;

  Future<void> load() async {
    if (_loading || isClosed) return;
    _loading = true;
    emit(const ProductDetailLoading());
    ProductDetailState next;
    try {
      next = ProductDetailLoaded(await _repository.detail(_id));
    } catch (error) {
      next = ProductDetailFailed(
        error is OfflineException
            ? 'Connect to download product details.'
            : 'Please try again.',
      );
    }
    _loading = false;
    if (!isClosed) emit(next);
  }
}
