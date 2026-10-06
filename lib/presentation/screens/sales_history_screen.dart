import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/sale_repository.dart';
import '../../services/locale_service.dart';
import 'invoice_preview_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SaleRepository _repository = SaleRepository();
  List<SaleModel> _sales = [];
  bool _isLoading = true;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    final sales = await _repository.getSales(
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      limit: 100,
    );
    setState(() {
      _sales = sales;
      _isLoading = false;
    });
  }

  Map<String, dynamic> _salesSummary() {
    final totalRevenue = _sales.fold<double>(0, (sum, sale) => sum + sale.grandTotal);
    final paidCount = _sales.where((sale) => sale.paymentStatus == 'paid').length;
    final pendingCount = _sales.where((sale) => sale.paymentStatus != 'paid').length;

    return {
      'totalRevenue': totalRevenue,
      'count': _sales.length,
      'paidCount': paidCount,
      'pendingCount': pendingCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final summary = _salesSummary();
    return Scaffold(
      appBar: AppBar(
        title: Text(localeService.localize('Sales History', 'سجل المبيعات')),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (range != null) {
                setState(() => _dateRange = range);
                _loadSales();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_sales.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            localeService.localize('Sales', 'مبيعات'),
                            summary['count'].toString(),
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _summaryCard(
                            localeService.localize('Revenue', 'الإيراد'),
                            '\$${(summary['totalRevenue'] as double).toStringAsFixed(2)}',
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _summaryCard(
                            localeService.localize('Paid', 'مدفوع'),
                            summary['paidCount'].toString(),
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_sales.isEmpty)
                  Expanded(
                    child: Center(child: Text(localeService.localize('No sales found', 'لم يتم العثور على مبيعات'))),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _sales.length,
                      itemBuilder: (context, index) {
                        final sale = _sales[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sale.paymentStatus == 'paid'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              child: Icon(
                                sale.paymentStatus == 'paid' ? Icons.check : Icons.pending,
                                color: sale.paymentStatus == 'paid' ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate)),
                                if (sale.customerName != null) Text(sale.customerName!),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${sale.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(sale.paymentMethod.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                            onTap: () async {
                              final fullSale = await _repository.getSaleWithItems(sale.id!);
                              if (fullSale != null && context.mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(sale: fullSale)));
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
