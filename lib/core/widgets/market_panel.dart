import 'package:material_ui/material_ui.dart';

class const MarketPanel({
  super.key,
  required final Widget child,
  final EdgeInsetsGeometry padding = const EdgeInsets.all(16),
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
