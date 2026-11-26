import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/theme/market_theme.dart';
import 'package:grocer_mate/core/widgets/product_photo.dart';

class const MarketHero({super.key, required final VoidCallback onDeals})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: .circular(18),
      child: ColoredBox(
        color: const Color(0xff15382b),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            return Stack(
              children: [
                Positioned.fill(
                  left: constraints.maxWidth * (wide ? .32 : .33),
                  child: const ProductPhoto('assets/photos/market.webp'),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff15382b),
                          const Color(0xff15382b),
                          const Color(0xff15382b).withValues(alpha: .7),
                          Colors.transparent,
                        ],
                        stops: const [0, .31, .48, .71],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: .symmetric(horizontal: wide ? 30 : 17, vertical: 19),
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    children: [
                      Text(
                        'Fresh finds,\nbetter prices.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: wide ? 39 : 28,
                          fontWeight: .w800,
                          height: 1.06,
                          letterSpacing: -.85,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onDeals,
                        style: FilledButton.styleFrom(
                          backgroundColor: lime,
                          foregroundColor: const Color(0xff173722),
                          padding: const .symmetric(horizontal: 12),
                        ),
                        child: const Text('Shop deals'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
