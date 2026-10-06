import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/product_model.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository<ProductModel> {
  @override
  String get tableName => 'products';

  @override
  ProductModel fromMap(Map<String, dynamic> map) => ProductModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ProductModel item) => item.toMap();

  Future<List<ProductModel>> searchProducts(String query, {int? categoryId, bool lowStock = false}) async {
    final db = await database;
    String whereClause = '(name LIKE ? OR barcode LIKE ? OR sku LIKE ? OR name_ar LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%', '%$query%'];

    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (lowStock) {
      whereClause += ' AND stock_quantity <= min_stock';
    }

    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return maps.map(fromMap).toList();
  }

  Future<ProductModel?> getByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(tableName, where: 'barcode = ?', whereArgs: [barcode]);
    if (maps.isNotEmpty) return fromMap(maps.first);
    return null;
  }

  Future<List<ProductModel>> getLowStock() async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'stock_quantity <= min_stock AND is_active = 1',
      orderBy: 'stock_quantity ASC',
    );
    return maps.map(fromMap).toList();
  }

  Future<List<ProductModel>> getExpiredProducts() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      tableName,
      where: 'expiry_date < ? AND expiry_date IS NOT NULL',
      whereArgs: [now],
      orderBy: 'expiry_date ASC',
    );
    return maps.map(fromMap).toList();
  }

  Future<List<ProductModel>> getNearExpiry({int days = 30}) async {
    final db = await database;
    final threshold = DateTime.now().add(Duration(days: days)).toIso8601String();
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      tableName,
      where: 'expiry_date <= ? AND expiry_date >= ? AND expiry_date IS NOT NULL',
      whereArgs: [threshold, now],
      orderBy: 'expiry_date ASC',
    );
    return maps.map(fromMap).toList();
  }

  Future<void> updateStock(int productId, double quantity, {int? warehouseId}) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
      [quantity, DateTime.now().toIso8601String(), productId],
    );

    if (warehouseId != null) {
      await db.rawUpdate('''
        INSERT INTO product_warehouse_stock (product_id, warehouse_id, quantity, updated_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(product_id, warehouse_id) 
        DO UPDATE SET quantity = quantity + excluded.quantity, updated_at = excluded.updated_at
      ''', [productId, warehouseId, quantity, DateTime.now().toIso8601String()]);
    }
  }

  Future<List<Map<String, dynamic>>> getTopSelling({int limit = 10, String period = 'today'}) async {
    final db = await database;
    String dateFilter = '';

    switch (period) {
      case 'today':
        dateFilter = "AND date(s.sale_date) = date('now')";
        break;
      case 'week':
        dateFilter = "AND s.sale_date >= date('now', '-7 days')";
        break;
      case 'month':
        dateFilter = "AND s.sale_date >= date('now', '-30 days')";
        break;
    }

    final result = await db.rawQuery('''
      SELECT p.id, p.name, p.name_ar, p.barcode, SUM(si.quantity) as total_qty, SUM(si.total) as total_revenue
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN sales s ON si.sale_id = s.id
      WHERE 1=1 $dateFilter
      GROUP BY si.product_id
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [limit]);

    return result;
  }
}
