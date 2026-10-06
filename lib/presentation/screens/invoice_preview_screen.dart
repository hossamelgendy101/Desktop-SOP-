import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/sale_model.dart';
import '../../services/locale_service.dart';
import '../../services/print_service.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final SaleModel sale;
  const InvoicePreviewScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final isArabic = localeService.locale.languageCode == 'ar';
    final items = sale.items ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F2335),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2335),
        foregroundColor: Colors.white,
        title: Text(localeService.localize('Invoice Preview', 'معاينة الفاتورة')),
        actions: [
          IconButton(icon: const Icon(Icons.print), onPressed: () => PrintService().printThermalReceipt(sale)),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () => PrintService().printA4Invoice(sale)),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 430,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF122B3E),
              border: Border.all(color: Colors.white24),
            ),
            child: Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E90FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localeService.localize('MY STORE', 'متجري'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localeService.localize('123 Main Street, City', '123 الشارع الرئيسي، المدينة'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    localeService.localize('Tel: +1234567890', 'الهاتف: +1234567890'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Divider(color: Colors.white30, height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${localeService.localize('Date', 'التاريخ')}: ${sale.saleDate.toString().substring(0, 16)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        sale.invoiceNumber,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${localeService.localize('Cashier', 'الكاشير')}:',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        sale.cashierName ?? localeService.localize('System Administrator', 'System Administrator'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white30, height: 28),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        localeService.localize('No items in this invoice', 'لا توجد عناصر في هذه الفاتورة'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.productName ?? localeService.localize('Unknown', 'غير معروف')}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.quantity.toStringAsFixed(1)}x @ \$${item.unitPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF2DA8FF), fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                        )),
                  const Divider(color: Colors.white30, height: 28),
                  _buildReceiptRow(
                    label: localeService.localize('Subtotal', 'الإجمالي الفرعي'),
                    value: sale.subtotal,
                    isBold: false,
                  ),
                  if (sale.discountAmount > 0)
                    _buildReceiptRow(
                      label: localeService.localize('Discount', 'خصم'),
                      value: sale.discountAmount,
                      isDiscount: true,
                    ),
                  if (sale.taxAmount > 0)
                    _buildReceiptRow(
                      label: localeService.localize('Tax', 'ضريبة'),
                      value: sale.taxAmount,
                    ),
                  const Divider(color: Colors.white30, height: 16),
                  _buildReceiptRow(
                    label: localeService.localize('TOTAL', 'الإجمالي'),
                    value: sale.grandTotal,
                    isBold: true,
                    valueColor: const Color(0xFF2DA8FF),
                  ),
                  _buildReceiptRow(
                    label: localeService.localize('Paid', 'مدفوع'),
                    value: sale.paidAmount,
                  ),
                  _buildReceiptRow(
                    label: localeService.localize('Change', 'الباقي'),
                    value: sale.changeAmount,
                  ),
                  const SizedBox(height: 18),
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: sale.invoiceNumber,
                    height: 68,
                    width: 330,
                    drawText: true,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  QrImageView(
                    data: sale.invoiceNumber,
                    size: 120,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localeService.localize('Thank you for your purchase!', 'شكرًا لك على شرائك!'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required double value,
    bool isBold = false,
    bool isDiscount = false,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white70,
              fontSize: isBold ? 17 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDiscount ? Colors.red : valueColor,
              fontSize: isBold ? 18 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
