import 'package:material_ui/material_ui.dart';

class const ConditionalBuilder({
  super.key,
  required final bool condition,
  required final WidgetBuilder onTrue,
  final WidgetBuilder? onFalse,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => condition
      ? onTrue(context)
      : (onFalse?.call(context) ?? const SizedBox.shrink());
}
