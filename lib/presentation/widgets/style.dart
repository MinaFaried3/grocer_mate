import 'package:material_ui/material_ui.dart';

const forest = Color(0xff174735);
const lime = Color(0xffd9f491);
const canvas = Color(0xfff8f8f1);

String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

ThemeData marketTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
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
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 66,
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 46),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.3,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.55,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.4,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class MarketPanel extends StatelessWidget {
  const MarketPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

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

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Icon(icon, size: 25),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

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
