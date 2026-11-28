import 'package:equatable/equatable.dart';

import '../../domain/entities/shopping.dart';

class const ShopState({
  final ShoppingData? data,
  final bool busy = false,
  final bool loadError = false,
  final CheckoutReviewMemento? review,
  final String? notice,
}) extends Equatable {
  ShopState copyWith({
    ShoppingData? data,
    bool? busy,
    bool? loadError,
    CheckoutReviewMemento? review,
    bool clearReview = false,
    String? notice,
    bool clearNotice = false,
  }) => .new(
    data: data ?? this.data,
    busy: busy ?? this.busy,
    loadError: loadError ?? this.loadError,
    review: clearReview ? null : review ?? this.review,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [data, busy, loadError, review, notice];
}
