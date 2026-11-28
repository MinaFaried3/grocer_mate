import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

class const ProductPhoto(
  final String path, {
  super.key,
  final int? cacheWidth,
  final BoxFit fit = .cover,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //------------ Fallback Placeholder ---------------
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        ColoredBox(
          color: context.colorScheme.primaryContainer,
          child: const Center(child: Icon(Icons.shopping_basket_outlined)),
        );

    //------------ Network Image ---------------
    final scheme = Uri.tryParse(path)?.scheme;
    if (scheme == 'http' || scheme == 'https') {
      return Image.network(
        path,
        fit: fit,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
        excludeFromSemantics: true,
        errorBuilder: fallback,
      );
    }

    //------------ Asset Image ---------------
    return Image.asset(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      width: double.infinity,
      height: double.infinity,
      excludeFromSemantics: true,
      errorBuilder: fallback,
    );
  }
}
