import 'package:material_ui/material_ui.dart';

const forest = Color(0xff174735);
const lime = Color(0xffd9f491);
const canvas = Color(0xfff8f8f1);

ThemeData marketTheme(Brightness brightness) {
  final dark = brightness == .dark;
  final scheme = ColorScheme.fromSeed(seedColor: forest, brightness: brightness)
      .copyWith(
        primary: dark ? const Color(0xffa8da9d) : forest,
        onPrimary: dark ? const Color(0xff102a1b) : Colors.white,
        primaryContainer: dark
            ? const Color(0xff2c4937)
            : const Color(0xffe7efdd),
        onPrimaryContainer: dark ? const Color(0xffd2ebc2) : forest,
        surface: dark ? const Color(0xff232824) : const Color(0xfffffff9),
        outlineVariant: dark
            ? const Color(0xff414942)
            : const Color(0xffe0e4d8),
      );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xff181d19) : canvas,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xff181d19) : canvas,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: .w800,
        color: scheme.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 66,
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: .w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 46),
        textStyle: const TextStyle(fontWeight: .w700),
        shape: RoundedRectangleBorder(borderRadius: .circular(13)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const .symmetric(vertical: 13, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: .circular(13),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: .circular(13),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: .w800,
        letterSpacing: -1.3,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: .w800,
        letterSpacing: -.55,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: .w800,
        letterSpacing: -.4,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: .w700),
    ),
  );
}
