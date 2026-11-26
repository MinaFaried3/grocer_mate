import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/network/app_network_state.dart';
import 'package:grocer_mate/core/theme/theme_context.dart';

import 'checkout_settings.dart';

class const SettingsSheet({super.key, required final CheckoutSettings settings})
    extends StatefulWidget {
  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState() extends State<SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final connection = context.read<AppConnection>();
    final settings = widget.settings;
    final textTheme = context.textTheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const .fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            Text('Settings', style: textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('Changes for next checkout', style: textTheme.titleSmall),
            RadioGroup<CheckoutUpdate>(
              groupValue: settings.nextCheckoutUpdate,
              onChanged: (value) {
                if (value != null) {
                  setState(() => settings.nextCheckoutUpdate = value);
                }
              },
              child: Column(
                mainAxisSize: .min,
                children: [
                  for (final update in CheckoutUpdate.values)
                    RadioListTile<CheckoutUpdate>(
                      value: update,
                      title: Text(update.label),
                      dense: true,
                      visualDensity: .compact,
                      contentPadding: .zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            BlocSelector<AppConnection, AppNetworkState, bool>(
              selector: (state) => state.offlineMode,
              builder: (context, offlineMode) => SwitchListTile(
                contentPadding: .zero,
                title: const Text('Offline mode'),
                subtitle: const Text(
                  'Browse cached groceries and queue purchases.',
                ),
                value: offlineMode,
                onChanged: (value) {
                  if (!value) Navigator.of(context).pop();
                  connection.setOfflineMode(value);
                },
              ),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
