import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/product_model.dart';
import '../../services/barcode_service.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final Function(ProductModel) onSave;

  const ProductFormDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();
  final _sellingCtrl = TextEditingController();
  final _wholesaleCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();

  String? _requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _requiredNumber(String? value, String fieldName) {
    final message = _requiredText(value, fieldName);
    if (message != null) return message;

    final number = double.tryParse(value!.trim());
    if (number == null || number < 0) return 'Enter a valid $fieldName';
    return null;
  }

  double _toDouble(String? value, {double fallback = 0}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return double.tryParse(value.trim()) ?? fallback;
  }

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _nameArCtrl.text = p.nameAr ?? '';
      _skuCtrl.text = p.sku ?? '';
      _barcodeCtrl.text = p.barcode ?? '';
      _purchaseCtrl.text = p.purchasePrice.toString();
      _sellingCtrl.text = p.sellingPrice.toString();
      _wholesaleCtrl.text = p.wholesalePrice.toString();
      _stockCtrl.text = p.stockQuantity.toString();
      _minStockCtrl.text = p.minStock.toString();
      return;
    }

    final generatedSku = BarcodeService().generateSKU();
    _skuCtrl.text = generatedSku;
    _barcodeCtrl.text = generatedSku;
    _stockCtrl.text = '0';
    _minStockCtrl.text = '0';
    _purchaseCtrl.text = '0';
    _sellingCtrl.text = '0';
    _wholesaleCtrl.text = '0';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchaseCtrl.dispose();
    _sellingCtrl.dispose();
    _wholesaleCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name *'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => _requiredText(v, 'Product name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameArCtrl,
                  decoration: const InputDecoration(labelText: 'Arabic Name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuCtrl,
                        decoration: const InputDecoration(labelText: 'SKU'),
                        readOnly: widget.product == null,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Generate new SKU',
                      onPressed: () {
                        setState(() {
                          _skuCtrl.text = BarcodeService().generateSKU();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcodeCtrl,
                  decoration: const InputDecoration(labelText: 'Barcode'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchaseCtrl,
                        decoration: const InputDecoration(labelText: 'Purchase Price'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                        validator: (v) => _requiredNumber(v, 'Purchase price'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingCtrl,
                        decoration: const InputDecoration(labelText: 'Selling Price *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                        validator: (v) {
                          final message = _requiredNumber(v, 'Selling price');
                          if (message != null) return message;

                          final selling = double.tryParse(v!.trim()) ?? 0;
                          final purchase = _toDouble(_purchaseCtrl.text);
                          if (purchase > 0 && selling < purchase) {
                            return 'Selling price cannot be lower than purchase price';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _wholesaleCtrl,
                  decoration: const InputDecoration(labelText: 'Wholesale Price'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                  validator: (v) => _requiredNumber(v, 'Wholesale price'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stock Quantity'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                        validator: (v) => _requiredNumber(v, 'Stock quantity'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockCtrl,
                        decoration: const InputDecoration(labelText: 'Min Stock'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                        validator: (v) => _requiredNumber(v, 'Min stock'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_alt),
          label: const Text('Save Product'),
        ),
      ],
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final now = DateTime.now();
    final name = _nameCtrl.text.trim();
    final sku = _skuCtrl.text.trim();
    final barcode = _barcodeCtrl.text.trim();
    final purchasePrice = _toDouble(_purchaseCtrl.text);
    final sellingPrice = _toDouble(_sellingCtrl.text);
    final wholesalePrice = _toDouble(_wholesaleCtrl.text);
    final stockQuantity = _toDouble(_stockCtrl.text);
    final minStock = _toDouble(_minStockCtrl.text);

    final product = ProductModel(
      id: widget.product?.id,
      sku: sku.isEmpty ? BarcodeService().generateSKU() : sku,
      barcode: barcode.isEmpty ? BarcodeService().generateSKU() : barcode,
      name: name,
      nameAr: _nameArCtrl.text.trim().isEmpty ? null : _nameArCtrl.text.trim(),
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      wholesalePrice: wholesalePrice,
      retailPrice: sellingPrice,
      stockQuantity: stockQuantity,
      minStock: minStock,
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(product);
    Navigator.pop(context);
  }
}
