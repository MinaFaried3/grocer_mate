import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../widgets/shopping_items_list.dart';

class const SavedScreen({
  super.key,
  required final VoidCallback onBrowse,
  required final VoidCallback onSettings,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ShoppingItemsList(
    storageKey: 'saved',
    title: 'Saved for later',
    saved: true,
    selectLines: (data) => data.saved,
    onSettings: onSettings,
    emptyState: StatusPanel(
      icon: Icons.bookmark_border_rounded,
      title: 'Nothing saved yet',
      message: 'Move items here from your cart to keep them handy.',
      action: 'Browse groceries',
      onAction: onBrowse,
    ),
  );
}
