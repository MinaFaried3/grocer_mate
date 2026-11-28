import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../../controllers/product_detail_controller.dart';
import '../widgets/product_details.dart';

class const ProductScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ProductDetailController, ProductDetailState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text(switch (state) {
              ProductDetailLoaded(:final product) => product.title,
              _ => 'Product details',
            }),
          ),
          body: switch (state) {
            ProductDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProductDetailFailed(:final message) => StatusPanel(
              icon: Icons.error_outline,
              title: 'Couldn’t open product',
              message: message,
              action: 'Try again',
              onAction: context.read<ProductDetailController>().load,
            ),
            ProductDetailLoaded(:final product) => ProductDetails(product),
          },
        ),
      );
}
