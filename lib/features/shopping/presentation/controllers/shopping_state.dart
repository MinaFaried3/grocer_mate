import '../../domain/shopping.dart';

class const ShopState({
  final ShoppingData? data,
  final bool busy = false,
  final bool loadError = false,
  final PurchaseReview? review,
  final String? notice,
}) {
  ShopState copyWith({
    ShoppingData? data,
    bool? busy,
    bool? loadError,
    PurchaseReview? review,
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
}
