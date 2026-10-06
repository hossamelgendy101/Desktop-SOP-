import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../data/models/sale_model.dart';

class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  Future<void> printThermalReceipt(SaleModel sale, {String? storeName, String? storeAddress, String? storePhone}) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(storeName ?? 'MY STORE', styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text(storeAddress ?? '', styles: PosStyles(align: PosAlign.center));
    bytes += generator.text(storePhone ?? '', styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    bytes += generator.text('Invoice: ${sale.invoiceNumber}');
    bytes += generator.text('Date: ${sale.saleDate.toString().substring(0, 16)}');
    bytes += generator.text('Cashier: ${sale.cashierName ?? "Unknown"}');
    if (sale.customerName != null) {
      bytes += generator.text('Customer: ${sale.customerName}');
    }
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
      PosColumn(text: 'Price', width: 2, styles: PosStyles(bold: true)),
      PosColumn(text: 'Total', width: 2, styles: PosStyles(bold: true)),
    ]);

    for (final item in sale.items ?? []) {
      bytes += generator.row([
        PosColumn(text: item.productName ?? 'Unknown', width: 6),
        PosColumn(text: item.quantity.toStringAsFixed(2), width: 2),
        PosColumn(text: item.unitPrice.toStringAsFixed(2), width: 2),
        PosColumn(text: item.total.toStringAsFixed(2), width: 2),
      ]);
    }

    bytes += generator.hr();

    bytes += generator.text('Subtotal: ${sale.subtotal.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.right));
    if (sale.discountAmount > 0) {
      bytes += generator.text('Discount: -${sale.discountAmount.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.right));
    }
    if (sale.taxAmount > 0) {
      bytes += generator.text('Tax: ${sale.taxAmount.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.right));
    }
    bytes += generator.text('TOTAL: ${sale.grandTotal.toStringAsFixed(2)}',
        styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2));
    bytes += generator.text('Paid: ${sale.paidAmount.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.right));
    bytes += generator.text('Change: ${sale.changeAmount.toStringAsFixed(2)}', styles: PosStyles(align: PosAlign.right));

    bytes += generator.hr();
    bytes += generator.text('Thank you for your purchase!', styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Please come again', styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    await Printing.directPrintPdf(
      printer: await _getDefaultPrinter(),
      onLayout: (_) => Uint8List.fromList(bytes),
    );
  }

  Future<void> printA4Invoice(SaleModel sale) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Invoice #: ${sale.invoiceNumber}'),
              pw.Text('Date: ${sale.saleDate}'),
              pw.Divider(),
              pw.Table.fromTextArray(
                headers: ['Product', 'Qty', 'Unit Price', 'Total'],
                data: sale.items?.map((item) => [
                  item.productName ?? '',
                  item.quantity.toStringAsFixed(2),
                  item.unitPrice.toStringAsFixed(2),
                  item.total.toStringAsFixed(2),
                ]).toList() ?? [],
              ),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${sale.subtotal.toStringAsFixed(2)}'),
                    pw.Text('Discount: ${sale.discountAmount.toStringAsFixed(2)}'),
                    pw.Text('Tax: ${sale.taxAmount.toStringAsFixed(2)}'),
                    pw.Text('Grand Total: ${sale.grandTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<Printer> _getDefaultPrinter() async {
    final printers = await Printing.listPrinters();
    return printers.firstWhere(
      (p) => p.isDefault,
      orElse: () => printers.first,
    );
  }
}
