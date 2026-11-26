import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/cart_product.dart';
import '../domain/entities/shopping.dart';

ShoppingData decodeShopping(Map<String, dynamic> json) {
  final pending = json['pending'];
  return .new(
    cart: _decodeLines(json['cart']),
    saved: _decodeLines(json['saved']),
    pending: pending == null
        ? null
        : .new(
            readText(pending, 'id'),
            _decodeLines(pending['lines']),
            attempted: pending['attempted'] as bool? ?? false,
          ),
    lastOrder: json['lastOrder'] == null
        ? null
        : decodeReceipt(json['lastOrder']),
  );
}

List<CartLine> _decodeLines(List<dynamic> lines) => .unmodifiable(
  lines.map((json) {
    final Map<String, dynamic> product = json['product'];
    // Earlier carts stored the whole catalog product, including its image list.
    final image = switch (product) {
      {'image': _} => readText(product, 'image'),
      {'images': [String first, ...]} when first.trim().isNotEmpty => first,
      _ => throw const FormatException('Cart product is missing its image.'),
    };
    return CartLine(
      CartProduct(
        id: readText(product, 'id'),
        title: readText(product, 'title'),
        image: image,
        price: readInt(product, 'price'),
        originalPrice: readInt(product, 'originalPrice'),
        stock: readInt(product, 'stock'),
      ),
      readInt(json, 'quantity', minimum: 1),
    );
  }),
);

Map<String, Object?> encodeShopping(ShoppingData data) {
  final pending = data.pending;
  return {
    'cart': _encodeLines(data.cart),
    'saved': _encodeLines(data.saved),
    'pending': pending == null
        ? null
        : {
            'id': pending.id,
            'lines': _encodeLines(pending.lines),
            'attempted': pending.attempted,
          },
    'lastOrder': data.lastOrder == null ? null : encodeReceipt(data.lastOrder!),
  };
}

List<Map<String, Object>> _encodeLines(List<CartLine> lines) => [
  for (final line in lines)
    {
      'product': {
        'id': line.product.id,
        'title': line.product.title,
        'image': line.product.image,
        'price': line.product.price,
        'originalPrice': line.product.originalPrice,
        'stock': line.product.stock,
      },
      'quantity': line.quantity,
    },
];

OrderReceipt decodeReceipt(Map<String, dynamic> json) =>
    .new(id: readText(json, 'id'), total: readInt(json, 'total'));

Map<String, Object> encodeReceipt(OrderReceipt receipt) => {
  'id': receipt.id,
  'total': receipt.total,
};
