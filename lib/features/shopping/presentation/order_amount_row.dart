import 'package:material_ui/material_ui.dart';

class const OrderAmountRow(final String label, final String amount, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(amount),
      ],
    ),
  );
}
