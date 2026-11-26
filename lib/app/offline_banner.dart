import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/network/app_connection.dart';

class const OfflineBanner({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final online = context.select(
      (AppConnection connection) => connection.online,
    );
    if (online) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.primaryContainer,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const .symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: .center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 17,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Offline mode · browsing the cached catalog',
                    style: TextStyle(
                      fontWeight: .w700,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
