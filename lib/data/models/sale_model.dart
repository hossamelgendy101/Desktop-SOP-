class SaleModel {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final int? warehouseId;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime saleDate;
  final int cashierId;
  final String? notes;
  final bool isReturned;
  final DateTime createdAt;
  final List<SaleItemModel>? items;

  final String? customerName;
  final String? cashierName;

  SaleModel({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.warehouseId,
    this.subtotal = 0,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.grandTotal = 0,
    this.paidAmount = 0,
    this.changeAmount = 0,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'paid',
    required this.saleDate,
    required this.cashierId,
    this.notes,
    this.isReturned = false,
    required this.createdAt,
    this.items,
    this.customerName,
    this.cashierName,
  });

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      customerId: map['customer_id'] as int?,
      warehouseId: map['warehouse_id'] as int?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      paymentStatus: map['payment_status'] as String? ?? 'paid',
      saleDate: DateTime.parse(map['sale_date'] as String),
      cashierId: map['cashier_id'] as int,
      notes: map['notes'] as String?,
      isReturned: (map['is_returned'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      customerName: map['customer_name'] as String?,
      cashierName: map['cashier_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'warehouse_id': warehouseId,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'sale_date': saleDate.toIso8601String(),
      'cashier_id': cashierId,
      'notes': notes,
      'is_returned': isReturned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SaleModel copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    int? warehouseId,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? grandTotal,
    double? paidAmount,
    double? changeAmount,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? saleDate,
    int? cashierId,
    String? notes,
    bool? isReturned,
    DateTime? createdAt,
    List<SaleItemModel>? items,
    String? customerName,
    String? cashierName,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      warehouseId: warehouseId ?? this.warehouseId,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      saleDate: saleDate ?? this.saleDate,
      cashierId: cashierId ?? this.cashierId,
      notes: notes ?? this.notes,
      isReturned: isReturned ?? this.isReturned,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      cashierName: cashierName ?? this.cashierName,
    );
  }
}

class SaleItemModel {
  final int? id;
  final int saleId;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double tax;
  final double total;
  final double costPrice;

  final String? productName;
  final String? productBarcode;

  SaleItemModel({
    this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    required this.costPrice,
    this.productName,
    this.productBarcode,
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      productId: map['product_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      productName: map['product_name'] as String?,
      productBarcode: map['product_barcode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'tax': tax,
      'total': total,
      'cost_price': costPrice,
    };
  }
}
