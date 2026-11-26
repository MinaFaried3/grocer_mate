import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/features/catalog/data/catalog_json.dart';
import 'package:grocer_mate/features/shopping/data/shopping_json.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/cart_operations.dart';

void main() {
  const product = {
    'id': 'milk',
    'title': 'Milk',
    'brand': 'Dairy',
    'categoryId': 'dairy',
    'price': 129,
    'originalPrice': 149,
    'stock': 2,
    'rating': 4.0,
    'images': ['milk.webp', 'detail.webp'],
    'description': 'Whole milk.',
    'badges': [],
    'nutrition': {'protein': 8},
    'allergens': ['milk'],
  };
  Map<String, dynamic> line(int quantity) => {
    'product': product,
    'quantity': quantity,
  };

  test('old cart, saved and attempted purchases survive compact storage', () {
    final old = decodeShopping({
      'cart': [line(1)],
      'saved': [line(3)],
      'pending': {
        'id': 'retry-1',
        'lines': [line(2)],
        'attempted': true,
      },
      'lastOrder': {'id': 'order-1', 'total': 235},
    });
    final encoded = encodeShopping(old);
    final compact = (encoded['cart'] as List).single['product'] as Map;
    expect(
      compact.keys,
      unorderedEquals([
        'id',
        'title',
        'image',
        'price',
        'originalPrice',
        'stock',
      ]),
    );
    final restored = decodeShopping(encoded);
    expect(restored.cart.single.product.image, 'milk.webp');
    expect(restored.lastOrder!.total, 235);
    expect(restored.pending!.id, 'retry-1');
    expect(restored.pending!.attempted, isTrue);
    expect(restored.pending!.lines.single.quantity, 2);

    const moveItems = MoveItems();
    final moved = moveItems((data: restored, ids: {'milk'}, fromSaved: true));
    expect(moved.limited, isTrue);
    expect(moved.data.cart.single.quantity, 2);
    expect(moved.data.saved.single.quantity, 2);
    expect(moved.data.pending, same(restored.pending));
  });

  test(
    'rejects invalid catalog prices, stock, images and saved quantities',
    () {
      for (final fields in [
        {'price': -1},
        {'stock': -1},
        {'images': []},
      ]) {
        expect(
          () => decodeProduct({...product, ...fields}),
          throwsFormatException,
        );
      }
      expect(
        () => decodeShopping({
          'cart': [line(0)],
          'saved': [],
        }),
        throwsFormatException,
      );
      expect(
        () => decodeShopping({
          'cart': [line(-1)],
          'saved': [],
        }),
        throwsFormatException,
      );
    },
  );
}
