import 'package:material_ui/material_ui.dart';

const forest = Color(0xff174735);
const lime = Color(0xffd9f491);
const canvas = Color(0xfff8f8f1);

abstract class const MarketThemeFactory() {
  static const MarketThemeFactory light = _LightMarketThemeFactory();
  static const MarketThemeFactory dark = _DarkMarketThemeFactory();

  Color get scaffoldBackgroundColor;
  ColorScheme createColorScheme();

  ThemeData build() {
    final scheme = createColorScheme();
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
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
}

class const _LightMarketThemeFactory() extends MarketThemeFactory {
  @override
  Color get scaffoldBackgroundColor => canvas;

  @override
  ColorScheme createColorScheme() => ColorScheme.fromSeed(
    seedColor: forest,
    brightness: .light,
    primary: forest,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xffe7efdd),
    onPrimaryContainer: forest,
    surface: const Color(0xfffffff9),
    outlineVariant: const Color(0xffe0e4d8),
  );
}

class const _DarkMarketThemeFactory() extends MarketThemeFactory {
  @override
  Color get scaffoldBackgroundColor => const Color(0xff181d19);

  @override
  ColorScheme createColorScheme() => ColorScheme.fromSeed(
    seedColor: forest,
    brightness: .dark,
    primary: const Color(0xffa8da9d),
    onPrimary: const Color(0xff102a1b),
    primaryContainer: const Color(0xff2c4937),
    onPrimaryContainer: const Color(0xffd2ebc2),
    surface: const Color(0xff232824),
    outlineVariant: const Color(0xff414942),
  );
}
