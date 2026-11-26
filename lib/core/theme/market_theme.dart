import 'package:material_ui/material_ui.dart';

import 'market_palette.dart' as palette;

export 'market_palette.dart' show canvas, forest, lime;

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
  Color get scaffoldBackgroundColor => palette.canvas;

  @override
  ColorScheme createColorScheme() => ColorScheme.fromSeed(
    seedColor: palette.forest,
    brightness: .light,
    primary: palette.forest,
    onPrimary: Colors.white,
    primaryContainer: palette.lightPrimaryContainer,
    onPrimaryContainer: palette.forest,
    surface: palette.lightSurface,
    outlineVariant: palette.lightOutlineVariant,
  );
}

class const _DarkMarketThemeFactory() extends MarketThemeFactory {
  @override
  Color get scaffoldBackgroundColor => palette.darkScaffoldBackground;

  @override
  ColorScheme createColorScheme() => ColorScheme.fromSeed(
    seedColor: palette.forest,
    brightness: .dark,
    primary: palette.darkPrimary,
    onPrimary: palette.darkOnPrimary,
    primaryContainer: palette.darkPrimaryContainer,
    onPrimaryContainer: palette.darkOnPrimaryContainer,
    surface: palette.darkSurface,
    outlineVariant: palette.darkOutlineVariant,
  );
}
