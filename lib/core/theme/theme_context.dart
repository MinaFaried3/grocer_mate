import 'package:material_ui/material_ui.dart';

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;
}
