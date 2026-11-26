import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

class const ProductPhoto(
  final String path, {
  super.key,
  final int? cacheWidth,
  final BoxFit fit = .cover,
}) extends StatelessWidget {
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
      color: context.colorScheme.primaryContainer,
      child: const Center(child: Icon(Icons.shopping_basket_outlined)),
    ),
  );
}
