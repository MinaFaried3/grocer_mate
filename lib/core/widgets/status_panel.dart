import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

class const StatusPanel({
  super.key,
  required final IconData icon,
  required final String title,
  required final String message,
  final String? action,
  final VoidCallback? onAction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Padding(
        padding: const .symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: .min,
          children: [
            //------------ Status Icon ---------------
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Icon(icon, size: 25),
            ),
            const SizedBox(height: 12),

            //------------ Title & Message ---------------
            Text(title, textAlign: .center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: .center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),

            //------------ Action Button ---------------
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
