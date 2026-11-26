import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../../../domain/entities/catalog.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../widgets/product_details.dart';

class const ProductScreen({super.key, required final String id})
    extends StatefulWidget {
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState() extends State<ProductScreen> {
  late Future<Product> _product;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _product = context.read<CatalogRepository>().detail(widget.id);

  @override
  Widget build(BuildContext context) => FutureBuilder<Product>(
    future: _product,
    builder: (context, snapshot) => Scaffold(
      appBar: AppBar(title: Text(snapshot.data?.title ?? 'Product details')),
      body: switch (snapshot) {
        AsyncSnapshot(connectionState: .waiting) => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncSnapshot(:final error?) => StatusPanel(
          icon: Icons.error_outline,
          title: 'Couldn’t open product',
          message: error is OfflineException
              ? 'Connect to download product details.'
              : 'Please try again.',
          action: 'Try again',
          onAction: () => setState(_load),
        ),
        _ => ProductDetails(snapshot.requireData),
      },
    ),
  );
}
