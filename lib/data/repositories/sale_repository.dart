import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_helper.dart';
import '../models/sale_model.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get database async => await _dbHelper.database;

  Future<int> createSale(SaleModel sale, List<SaleItemModel> items) async {
    final db = await database;
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (final item in items) {
        final itemMap = item.toMap();
        itemMap['sale_id'] = saleId;
        await txn.insert('sale_items', itemMap);

        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );

        await txn.insert('stock_movements', {
          'product_id': item.productId,
          'warehouse_id': sale.warehouseId,
          'movement_type': 'sale',
          'quantity': -item.quantity,
          'reference_type': 'sale',
          'reference_id': saleId,
          'created_by': sale.cashierId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return saleId;
    });
  }

  Future<SaleModel?> getSaleWithItems(int saleId) async {
    final db = await database;
    final saleMaps = await db.rawQuery('''
      SELECT s.*, c.name as customer_name, u.full_name as cashier_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      LEFT JOIN users u ON s.cashier_id = u.id
      WHERE s.id = ?
    ''', [saleId]);

    if (saleMaps.isEmpty) return null;

    final sale = SaleModel.fromMap(saleMaps.first);

    final itemMaps = await db.rawQuery('''
      SELECT si.*, p.name as product_name, p.barcode as product_barcode
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      WHERE si.sale_id = ?
    ''', [saleId]);

    return sale.copyWith(items: itemMaps.map((m) => SaleItemModel.fromMap(m)).toList());
  }

  Future<List<SaleModel>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    int? cashierId,
    String? paymentStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND date(sale_date) >= date(?)';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND date(sale_date) <= date(?)';
      whereArgs.add(endDate.toIso8601String());
    }
    if (cashierId != null) {
      whereClause += ' AND cashier_id = ?';
      whereArgs.add(cashierId);
    }
    if (paymentStatus != null) {
      whereClause += ' AND payment_status = ?';
      whereArgs.add(paymentStatus);
    }

    final maps = await db.query(
      'sales',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sale_date DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => SaleModel.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getSalesSummary({String period = 'today'}) async {
    final db = await database;
    String dateFilter = '';

    switch (period) {
      case 'today':
        dateFilter = "date(sale_date) = date('now')";
        break;
      case 'week':
        dateFilter = "sale_date >= date('now', '-7 days')";
        break;
      case 'month':
        dateFilter = "sale_date >= date('now', '-30 days')";
        break;
      case 'year':
        dateFilter = "sale_date >= date('now', '-365 days')";
        break;
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(grand_total), 0) as total,
        COALESCE(SUM(tax_amount), 0) as tax,
        COALESCE(SUM(discount_amount), 0) as discount,
        COALESCE(SUM(paid_amount), 0) as paid
      FROM sales
      WHERE $dateFilter
    ''');

    return result.first;
  }

  Future<int> holdInvoice(Map<String, dynamic> invoiceData, int cashierId, {int? customerId, double? totalAmount, String? holdName}) async {
    final db = await database;
    return await db.insert('held_invoices', {
      'invoice_data': invoiceData.toString(),
      'cashier_id': cashierId,
      'customer_id': customerId,
      'total_amount': totalAmount ?? 0,
      'hold_name': holdName,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHeldInvoices(int cashierId) async {
    final db = await database;
    return await db.query('held_invoices', where: 'cashier_id = ?', whereArgs: [cashierId]);
  }
}
