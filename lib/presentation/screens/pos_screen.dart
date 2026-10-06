import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/sale_repository.dart';
import '../../services/locale_service.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/pos_bloc.dart';
import '../widgets/product_search_delegate.dart';
import 'invoice_preview_screen.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().currentUser;
    return BlocProvider(
      create: (context) => PosBloc(
        productRepository: context.read<ProductRepository>(),
        saleRepository: context.read<SaleRepository>(),
        cashierId: user?.id ?? 1,
      ),
      child: const _PosScreenContent(),
    );
  }
}

class _PosScreenContent extends StatefulWidget {
  const _PosScreenContent();

  @override
  State<_PosScreenContent> createState() => _PosScreenContentState();
}

class _PosScreenContentState extends State<_PosScreenContent> {
  final _searchCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosBloc>().add(SearchProduct(''));
      _barcodeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _paidCtrl.dispose();
    _discountCtrl.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(localeService.localize('Point of Sale', 'نقطة البيع')),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: localeService.localize('Hold Invoice', 'حجز الفاتورة'),
            onPressed: () => _showHoldDialog(context, localeService),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: localeService.localize('Resume Invoice', 'استئناف الفاتورة'),
            onPressed: () => _showHeldInvoices(context, localeService),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<PosBloc, PosState>(
        listener: (context, state) {
          if (state is PosReady && state.lastSale != null) {
            _paidCtrl.clear();
            _discountCtrl.clear();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoicePreviewScreen(sale: state.lastSale!),
              ),
            );
          }
          if (state is PosReady && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is! PosReady) return const Center(child: CircularProgressIndicator());
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (event) {
                          if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                            if (_searchCtrl.text.isNotEmpty) {
                              context.read<PosBloc>().add(ScanBarcode(_searchCtrl.text.trim()));
                              _searchCtrl.clear();
                            }
                          }
                        },
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _barcodeFocus,
                          decoration: InputDecoration(
                            hintText: localeService.localize('Search product by name or barcode...', 'ابحث عن المنتج بالاسم أو الباركود...'),
                            prefixIcon: const Icon(Icons.qr_code_scanner),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => _showProductSearch(context, localeService),
                            ),
                          ),
                          onChanged: (value) {
                            context.read<PosBloc>().add(SearchProduct(value.trim()));
                          },
                          onSubmitted: (value) {
                            final query = value.trim();
                            if (query.isEmpty) {
                              context.read<PosBloc>().add(SearchProduct(''));
                              return;
                            }

                            context.read<PosBloc>().add(SearchProduct(query));
                            _barcodeFocus.requestFocus();
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.searchResults.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: Card(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: state.searchResults.length,
                              itemBuilder: (context, index) {
                                final product = state.searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: product.isLowStock ? Colors.orange.shade100 : Colors.green.shade100,
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: product.isLowStock ? Colors.orange : Colors.green,
                                    ),
                                  ),
                                  title: Text(product.name),
                                  subtitle: Text('${product.stockQuantity} in stock • \$${product.finalPrice.toStringAsFixed(2)}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green),
                                    onPressed: () {
                                      context.read<PosBloc>().add(AddToCart(product));
                                      _searchCtrl.clear();
                                      _barcodeFocus.requestFocus();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                localeService.localize('No products found', 'لم يتم العثور على منتجات'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.percent, size: 18),
                            label: Text(localeService.localize('Discount', 'خصم')),
                            onPressed: () => _showDiscountDialog(context, state, localeService),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.receipt_long, size: 18),
                            label: Text(localeService.localize('Tax', 'ضريبة')),
                            onPressed: () => _showTaxDialog(context, state, localeService),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.person_add, size: 18),
                            label: Text(localeService.localize('Customer', 'عميل')),
                            onPressed: () {},
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.clear_all, size: 18),
                            label: Text(localeService.localize('Clear', 'مسح')),
                            onPressed: () => context.read<PosBloc>().add(ClearCart()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 420,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart),
                          const SizedBox(width: 8),
                          Text(
                            '${localeService.localize('Cart', 'السلة')} (${state.cart.length} ${localeService.localize('items', 'عناصر')})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: state.cart.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(localeService.localize('Cart is empty', 'السلة فارغة'), style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: state.cart.length,
                              itemBuilder: (context, index) {
                                final item = state.cart[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text('\$${item.unitPrice.toStringAsFixed(2)} each', style: TextStyle(color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Decrease quantity',
                                            icon: const Icon(Icons.remove_circle_outline),
                                            onPressed: () {
                                              final qty = item.quantity - 1;
                                              if (qty <= 0) {
                                                context.read<PosBloc>().add(RemoveFromCart(item.product.id!));
                                              } else {
                                                context.read<PosBloc>().add(UpdateCartQuantity(item.product.id!, qty));
                                              }
                                            },
                                          ),
                                          SizedBox(
                                            width: 32,
                                            child: Center(
                                              child: Text(
                                                item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1),
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Increase quantity',
                                            icon: const Icon(Icons.add_circle_outline),
                                            onPressed: () => context.read<PosBloc>().add(UpdateCartQuantity(item.product.id!, item.quantity + 1)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                            onPressed: () => context.read<PosBloc>().add(RemoveFromCart(item.product.id!)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                      child: Column(
                        children: [
                          _buildTotalRow(localeService.localize('Subtotal', 'الإجمالي الفرعي'), state.subtotal),
                          if (state.discountAmount > 0)
                            _buildTotalRow(localeService.localize('Discount', 'خصم'), -state.discountAmount, isDiscount: true),
                          if (state.taxAmount > 0)
                            _buildTotalRow(localeService.localize('Tax', 'ضريبة'), state.taxAmount),
                          const Divider(),
                          _buildTotalRow(localeService.localize('Grand Total', 'الإجمالي الكلي'), state.grandTotal, isTotal: true),
                          _buildTotalRow(localeService.localize('Paid', 'مدفوع'), state.paidAmount),
                          _buildTotalRow(localeService.localize('Change', 'الباقي'), state.changeAmount),
                          const SizedBox(height: 16),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(value: 'cash', icon: const Icon(Icons.money), label: Text(localeService.localize('Cash', 'نقدي'))),
                              ButtonSegment(value: 'card', icon: const Icon(Icons.credit_card), label: Text(localeService.localize('Card', 'بطاقة'))),
                            ],
                            selected: {state.paymentMethod},
                            onSelectionChanged: (set) {
                              context.read<PosBloc>().add(SetPaymentMethod(set.first));
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _paidCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: localeService.localize('Paid Amount', 'المبلغ المدفوع'), prefixText: '\$ '),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: state.cart.isEmpty || state.isProcessing
                                  ? null
                                  : () {
                                      final paid = double.tryParse(_paidCtrl.text) ?? state.grandTotal;
                                      if (paid < state.grandTotal) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(localeService.localize('Paid amount is less than total', 'المبلغ المدفوع أقل من الإجمالي')),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      context.read<PosBloc>().add(ProcessPayment(paid));
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: state.isProcessing
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(localeService.localize('COMPLETE SALE', 'إتمام البيع'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${isDiscount ? '-' : ''}\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? Colors.red : isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSearch(BuildContext context, LocaleService localeService) {
    showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        onProductSelected: (product) {
          context.read<PosBloc>().add(AddToCart(product));
        },
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, PosReady state, LocaleService localeService) {
    final discountController = TextEditingController(text: (state.discountAmount > 0 ? state.discountAmount : 0).toString());
    final isPercentage = ValueNotifier<bool>(true);

    showDialog(
      context: context,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: isPercentage,
        builder: (context, percentageMode, _) => AlertDialog(
          title: Text(localeService.localize('Apply Discount', 'تطبيق الخصم')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(localeService.localize('Percent', 'نسبة'))),
                  ButtonSegment(value: false, label: Text(localeService.localize('Fixed', 'مبلغ ثابت'))),
                ],
                selected: {percentageMode},
                onSelectionChanged: (value) => isPercentage.value = value.first,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: percentageMode
                      ? localeService.localize('Discount %', 'نسبة الخصم')
                      : localeService.localize('Discount Amount', 'مبلغ الخصم'),
                  suffixText: percentageMode ? '%' : '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(localeService.localize('Cancel', 'إلغاء'))),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(discountController.text) ?? 0;
                context.read<PosBloc>().add(ApplyDiscount(value, isPercentage: percentageMode));
                Navigator.pop(context);
              },
              child: Text(localeService.localize('Apply', 'تطبيق')),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaxDialog(BuildContext context, PosReady state, LocaleService localeService) {
    final taxController = TextEditingController(text: state.taxRate.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localeService.localize('Tax Rate', 'نسبة الضريبة')),
        content: TextField(
          controller: taxController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: localeService.localize('Tax %', 'ضريبة %'),
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localeService.localize('Cancel', 'إلغاء'))),
          ElevatedButton(
            onPressed: () {
              final rate = double.tryParse(taxController.text) ?? 0;
              context.read<PosBloc>().add(SetTaxRate(rate));
              Navigator.pop(context);
            },
            child: Text(localeService.localize('Apply', 'تطبيق')),
          ),
        ],
      ),
    );
  }

  void _showHoldDialog(BuildContext context, LocaleService localeService) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localeService.localize('Hold Invoice', 'حجز الفاتورة')),
        content: TextField(controller: nameCtrl, decoration: InputDecoration(labelText: localeService.localize('Hold Name (Optional)', 'اسم الحجز (اختياري)'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localeService.localize('Cancel', 'إلغاء'))),
          ElevatedButton(
            onPressed: () {
              context.read<PosBloc>().add(HoldInvoice(name: nameCtrl.text.isEmpty ? null : nameCtrl.text));
              Navigator.pop(context);
            },
            child: Text(localeService.localize('Hold', 'حفظ')),
          ),
        ],
      ),
    );
  }

  void _showHeldInvoices(BuildContext context, LocaleService localeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localeService.localize('Held Invoices', 'الفواتير المحفوظة')),
        content: Text(localeService.localize('Feature coming soon...', 'الميزة قادمة قريباً...')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(localeService.localize('Close', 'إغلاق')))],
      ),
    );
  }
}
