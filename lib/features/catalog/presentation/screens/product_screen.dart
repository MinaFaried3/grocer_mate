import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../../domain/catalog.dart';
import '../ui/product_details.dart';

class const ProductScreen({
  super.key,
  required final String id,
  required final String title,
}) extends StatefulWidget {
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<Product> _product;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _product = context.read<CatalogRepository>().detail(widget.id);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<Product>(
      future: _product,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return StatusPanel(
            icon: Icons.error_outline,
            title: 'Couldn’t open product',
            message: snapshot.error is OfflineException
                ? 'Connect to download product details.'
                : 'Please try again.',
            action: 'Try again',
            onAction: () => setState(_load),
          );
        }
        return ProductDetails(snapshot.requireData);
      },
    ),
  );
}
