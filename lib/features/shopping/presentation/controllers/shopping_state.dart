import '../../domain/shopping.dart';

class ShopState {
  const ShopState({
    this.data,
    this.busy = false,
    this.loadError = false,
    this.review,
    this.notice,
  });

  final ShoppingData? data;
  final bool busy;
  final bool loadError;
  final PurchaseReview? review;
  final String? notice;

  ShopState copyWith({
    ShoppingData? data,
    bool? busy,
    bool? loadError,
    PurchaseReview? review,
    bool clearReview = false,
    String? notice,
    bool clearNotice = false,
  }) => ShopState(
    data: data ?? this.data,
    busy: busy ?? this.busy,
    loadError: loadError ?? this.loadError,
    review: clearReview ? null : review ?? this.review,
    notice: clearNotice ? null : notice ?? this.notice,
  );
}
