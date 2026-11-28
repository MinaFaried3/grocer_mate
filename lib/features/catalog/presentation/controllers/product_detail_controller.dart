import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/network/connectivity/offline_exception.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/repositories/catalog_repository.dart';

sealed class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class const ProductDetailLoading() extends ProductDetailState;

class const ProductDetailLoaded(final Product product)
    extends ProductDetailState {
  @override
  List<Object?> get props => [product];
}

class const ProductDetailFailed(final String message)
    extends ProductDetailState {
  @override
  List<Object?> get props => [message];
}

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
