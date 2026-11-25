import 'package:material_ui/material_ui.dart';

class ProductPhoto extends StatelessWidget {
  const ProductPhoto(
    this.path, {
    super.key,
    this.cacheWidth,
    this.fit = BoxFit.cover,
  });
  final String path;
  final int? cacheWidth;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
    path,
    fit: fit,
    cacheWidth: cacheWidth,
    gaplessPlayback: true,
    width: double.infinity,
    height: double.infinity,
    excludeFromSemantics: true,
    errorBuilder: (context, error, stack) => ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Center(child: Icon(Icons.shopping_basket_outlined)),
    ),
  );
}
