import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/locale_service.dart';
import '../blocs/product_bloc.dart';
import '../widgets/product_form_dialog.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc(repository: context.read<ProductRepository>())..add(LoadProducts()),
      child: const _ProductsScreenContent(),
    );
  }
}

class _ProductsScreenContent extends StatelessWidget {
  const _ProductsScreenContent();

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(localeService.localize('Products', 'المنتجات')),
        actions: [
          IconButton(icon: const Icon(Icons.file_upload), tooltip: localeService.localize('Import', 'استيراد'), onPressed: () {}),
          IconButton(icon: const Icon(Icons.file_download), tooltip: localeService.localize('Export', 'تصدير'), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(hintText: localeService.localize('Search products...', 'ابحث عن المنتجات...'), prefixIcon: const Icon(Icons.search)),
              onChanged: (value) => context.read<ProductBloc>().add(SearchProducts(value)),
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) return const Center(child: CircularProgressIndicator());
                if (state is ProductError) return Center(child: Text('${localeService.localize('Error', 'خطأ')}: ${state.message}'));
                if (state is ProductLoaded) {
                  if (state.products.isEmpty) return Center(child: Text(localeService.localize('No products found', 'لم يتم العثور على منتجات')));
                  return ListView.builder(
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ProductListTile(
                        product: product,
                        onEdit: () => _showEditDialog(context, product),
                        onDelete: () => _confirmDelete(context, product),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: Text(localeService.localize('Add Product', 'إضافة منتج')),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final bloc = context.read<ProductBloc>();
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        onSave: (product) => bloc.add(AddProduct(product)),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ProductModel product) {
    final bloc = context.read<ProductBloc>();
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        onSave: (updated) => bloc.add(UpdateProduct(updated)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    final bloc = context.read<ProductBloc>();
    final localeService = context.read<LocaleService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localeService.localize('Delete Product', 'حذف المنتج')),
        content: Text(localeService.localize('Are you sure you want to delete "${product.name}"?', 'هل أنت متأكد أنك تريد حذف "${product.name}"؟')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localeService.localize('Cancel', 'إلغاء'))),
          ElevatedButton(
            onPressed: () {
              bloc.add(DeleteProduct(product.id!));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localeService.localize('Delete', 'حذف')),
          ),
        ],
      ),
    );
  }
}

class ProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductListTile({super.key, required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final isLowStock = product.isLowStock;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock ? Colors.red.withOpacity(0.1) : const Color(0xFF2563EB).withOpacity(0.1),
          child: Text(
            product.name.substring(0, 1).toUpperCase(),
            style: TextStyle(color: isLowStock ? Colors.red : const Color(0xFF2563EB), fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(localeService.localize('LOW STOCK', 'مخزون منخفض'), style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.sku ?? 'N/A'} | Barcode: ${product.barcode ?? 'N/A'}'),
            Text('Stock: ${product.stockQuantity} | Price: \$${product.sellingPrice.toStringAsFixed(2)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(localeService.localize('Edit', 'تعديل'))])),
            PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(localeService.localize('Delete', 'حذف'), style: const TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }
}
