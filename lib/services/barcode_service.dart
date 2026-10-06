import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  Widget generateBarcode(String data, {double width = 200, double height = 80}) {
    return bw.BarcodeWidget(
      barcode: bw.Barcode.code128(),
      data: data,
      width: width,
      height: height,
      drawText: true,
    );
  }

  Widget generateQRCode(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
    );
  }

  String generateSKU() {
    final now = DateTime.now();
    return 'SKU-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(6)}';
  }

  String generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }
}
