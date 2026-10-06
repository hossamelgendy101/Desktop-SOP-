class ProductModel {
  final int? id;
  final String? sku;
  final String? barcode;
  final String name;
  final String? nameAr;
  final String? description;
  final int? categoryId;
  final int? brandId;
  final int? unitId;
  final double purchasePrice;
  final double sellingPrice;
  final double wholesalePrice;
  final double retailPrice;
  final double? discountPrice;
  final double vatRate;
  final double taxRate;
  final double stockQuantity;
  final double minStock;
  final double maxStock;
  final DateTime? expiryDate;
  final DateTime? manufacturingDate;
  final String? imagePath;
  final bool isActive;
  final bool allowFractional;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? categoryName;
  final String? brandName;
  final String? unitName;

  ProductModel({
    this.id,
    this.sku,
    this.barcode,
    required this.name,
    this.nameAr,
    this.description,
    this.categoryId,
    this.brandId,
    this.unitId,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.wholesalePrice = 0,
    this.retailPrice = 0,
    this.discountPrice,
    this.vatRate = 0,
    this.taxRate = 0,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.maxStock = 0,
    this.expiryDate,
    this.manufacturingDate,
    this.imagePath,
    this.isActive = true,
    this.allowFractional = false,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.brandName,
    this.unitName,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      name: map['name'] as String,
      nameAr: map['name_ar'] as String?,
      description: map['description'] as String?,
      categoryId: map['category_id'] as int?,
      brandId: map['brand_id'] as int?,
      unitId: map['unit_id'] as int?,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0,
      retailPrice: (map['retail_price'] as num?)?.toDouble() ?? 0,
      discountPrice: (map['discount_price'] as num?)?.toDouble(),
      vatRate: (map['vat_rate'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0,
      minStock: (map['min_stock'] as num?)?.toDouble() ?? 0,
      maxStock: (map['max_stock'] as num?)?.toDouble() ?? 0,
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date'] as String) : null,
      manufacturingDate: map['manufacturing_date'] != null ? DateTime.parse(map['manufacturing_date'] as String) : null,
      imagePath: map['image_path'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      allowFractional: (map['allow_fractional'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      categoryName: map['category_name'] as String?,
      brandName: map['brand_name'] as String?,
      unitName: map['unit_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'name_ar': nameAr,
      'description': description,
      'category_id': categoryId,
      'brand_id': brandId,
      'unit_id': unitId,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'wholesale_price': wholesalePrice,
      'retail_price': retailPrice,
      'discount_price': discountPrice,
      'vat_rate': vatRate,
      'tax_rate': taxRate,
      'stock_quantity': stockQuantity,
      'min_stock': minStock,
      'max_stock': maxStock,
      'expiry_date': expiryDate?.toIso8601String(),
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'image_path': imagePath,
      'is_active': isActive ? 1 : 0,
      'allow_fractional': allowFractional ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isLowStock => stockQuantity <= minStock;
  bool get isNearExpiry {
    if (expiryDate == null) return false;
    return expiryDate!.difference(DateTime.now()).inDays <= 30;
  }

  double get finalPrice => discountPrice ?? sellingPrice;
}
