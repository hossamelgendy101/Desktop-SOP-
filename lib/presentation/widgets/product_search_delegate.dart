import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/locale_service.dart';

class ProductSearchDelegate extends SearchDelegate<ProductModel?> {
  final ProductRepository _repository;
  final Function(ProductModel) onProductSelected;

  ProductSearchDelegate({
    required this.onProductSelected,
    ProductRepository? repository,
  }) : _repository = repository ?? ProductRepository();

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context, listen: false);
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return Center(
        child: Text(
          localeService.localize('Type a product name or barcode', 'اكتب اسم المنتج أو الباركود'),
        ),
      );
    }

    return FutureBuilder<List<ProductModel>>(
      future: _repository.searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(localeService.localize('No products found', 'لم يتم العثور على منتجات')));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final product = snapshot.data![index];
            return ListTile(
              leading: CircleAvatar(child: Text(product.name.substring(0, 1).toUpperCase())),
              title: Text(product.name),
              subtitle: Text('Stock: ${product.stockQuantity} | \$${product.sellingPrice.toStringAsFixed(2)}'),
              trailing: Text(
                product.isLowStock ? localeService.localize('LOW', 'منخفض') : '',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onTap: () {
                onProductSelected(product);
                close(context, product);
              },
            );
          },
        );
      },
    );
  }
}
