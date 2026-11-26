import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/network/app_network_state.dart';

import 'mock_market.dart';

class const DemoSettingsSheet({super.key, required final MockMarket market})
    extends StatefulWidget {
  @override
  State<DemoSettingsSheet> createState() => _DemoSettingsState();
}

class _DemoSettingsState() extends State<DemoSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final connection = context.read<AppConnection>();
    final market = widget.market;
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const .fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            Text('Demo settings', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('Next checkout scenario', style: theme.textTheme.titleSmall),
            RadioGroup<CheckoutScenario>(
              groupValue: market.scenario,
              onChanged: (value) {
                if (value != null) setState(() => market.scenario = value);
              },
              child: Column(
                mainAxisSize: .min,
                children: [
                  for (final scenario in CheckoutScenario.values)
                    RadioListTile<CheckoutScenario>(
                      value: scenario,
                      title: Text(scenario.label),
                      dense: true,
                      visualDensity: .compact,
                      contentPadding: .zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            BlocSelector<AppConnection, AppNetworkState, bool>(
              selector: (state) => state.simulated,
              builder: (context, simulated) => SwitchListTile(
                contentPadding: .zero,
                title: const Text('Simulate offline'),
                subtitle: const Text(
                  'Test cached browsing and queued purchases.',
                ),
                value: simulated,
                onChanged: (value) {
                  if (!value) Navigator.of(context).pop();
                  connection.simulateOffline(value);
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
