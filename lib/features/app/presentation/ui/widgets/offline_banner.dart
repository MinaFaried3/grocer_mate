import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../controllers/app_connection_cubit.dart';

class const OfflineBanner({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final offline = context.select((AppConnectionCubit connection) {
      final state = connection.state;
      return state.offlineMode || state.connected == false;
    });
    if (!offline) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.primaryContainer,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const .all(8),
            child: Center(
              child: Text(
                'Offline mode · browsing the cached catalog',
                style: TextStyle(color: colors.onPrimaryContainer),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
