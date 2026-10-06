import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'pos_system.db';
  static const int _dbVersion = 2;

  final _key = encrypt.Key.fromUtf8('pos32charsecurekey123456789012');
  final _iv = encrypt.IV.fromLength(16);

  encrypt.Encrypter get _encrypter => encrypt.Encrypter(encrypt.AES(_key));

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final String path = join(documentsDir.path, _dbName);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        singleInstance: true,
      ),
    );
  }

  String encryptData(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  String decryptData(String encrypted) {
    return _encrypter.decrypt64(encrypted, iv: _iv);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        role TEXT NOT NULL CHECK(role IN ('admin', 'manager', 'cashier')),
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        last_login TEXT,
        permissions TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE store_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        store_name TEXT NOT NULL,
        store_address TEXT,
        store_phone TEXT,
        store_email TEXT,
        tax_number TEXT,
        currency_code TEXT DEFAULT 'USD',
        currency_symbol TEXT DEFAULT '\$',
        language TEXT DEFAULT 'en',
        theme_mode TEXT DEFAULT 'system',
        receipt_footer TEXT,
        logo_path TEXT,
        vat_rate REAL DEFAULT 0,
        enable_vat INTEGER DEFAULT 0,
        backup_frequency TEXT DEFAULT 'daily',
        last_backup TEXT,
        created_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_ar TEXT,
        description TEXT,
        color TEXT,
        icon TEXT,
        parent_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE brands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_ar TEXT,
        short_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT UNIQUE,
        barcode TEXT UNIQUE,
        name TEXT NOT NULL,
        name_ar TEXT,
        description TEXT,
        category_id INTEGER,
        brand_id INTEGER,
        unit_id INTEGER,
        purchase_price REAL DEFAULT 0,
        selling_price REAL DEFAULT 0,
        wholesale_price REAL DEFAULT 0,
        retail_price REAL DEFAULT 0,
        discount_price REAL,
        vat_rate REAL DEFAULT 0,
        tax_rate REAL DEFAULT 0,
        stock_quantity REAL DEFAULT 0,
        min_stock REAL DEFAULT 0,
        max_stock REAL DEFAULT 0,
        expiry_date TEXT,
        manufacturing_date TEXT,
        image_path TEXT,
        is_active INTEGER DEFAULT 1,
        allow_fractional INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (brand_id) REFERENCES brands (id),
        FOREIGN KEY (unit_id) REFERENCES units (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE product_warehouse_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        warehouse_id INTEGER NOT NULL,
        quantity REAL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id),
        UNIQUE(product_id, warehouse_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        balance REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        city TEXT,
        balance REAL DEFAULT 0,
        credit_limit REAL DEFAULT 0,
        loyalty_points INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        supplier_id INTEGER,
        warehouse_id INTEGER,
        total_amount REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        grand_total REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        payment_status TEXT DEFAULT 'unpaid',
        purchase_date TEXT NOT NULL,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id),
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total REAL NOT NULL,
        expiry_date TEXT,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        warehouse_id INTEGER,
        subtotal REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        grand_total REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        change_amount REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'cash',
        payment_status TEXT DEFAULT 'paid',
        sale_date TEXT NOT NULL,
        cashier_id INTEGER NOT NULL,
        notes TEXT,
        is_returned INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id),
        FOREIGN KEY (cashier_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total REAL NOT NULL,
        cost_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference_type TEXT NOT NULL,
        reference_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        amount REAL NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        is_recurring INTEGER DEFAULT 0,
        recurring_frequency TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES expense_categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        warehouse_id INTEGER NOT NULL,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        reference_type TEXT,
        reference_id INTEGER,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE,
        employee_code TEXT UNIQUE,
        salary REAL DEFAULT 0,
        hire_date TEXT,
        job_title TEXT,
        department TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        check_in TEXT,
        check_out TEXT,
        status TEXT DEFAULT 'present',
        notes TEXT,
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT NOT NULL,
        table_name TEXT,
        record_id INTEGER,
        old_values TEXT,
        new_values TEXT,
        ip_address TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE held_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_data TEXT NOT NULL,
        cashier_id INTEGER NOT NULL,
        customer_id INTEGER,
        total_amount REAL DEFAULT 0,
        hold_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    final now = DateTime.now().toIso8601String();
    final adminPasswordHash = sha256.convert(utf8.encode('admin123')).toString();
    await db.execute('''
      INSERT INTO users (username, password_hash, full_name, role, created_at, permissions)
      VALUES ('admin', '$adminPasswordHash', 'System Administrator', 'admin', '$now', 'all')
    ''');

    await db.execute('''
      INSERT INTO store_settings (id, store_name, store_address, store_phone, currency_code, currency_symbol, language, created_at)
      VALUES (1, 'My Store', 'Main Street', '+1234567890', 'USD', '\$', 'en', '$now')
    ''');

    await db.execute('''
      INSERT INTO warehouses (name, address, is_default, created_at)
      VALUES ('Main Warehouse', 'Main Branch', 1, '$now')
    ''');

    await db.execute('''
      INSERT INTO units (name, name_ar, short_name, created_at)
      VALUES ('Piece', 'قطعة', 'pc', '$now')
    ''');
  }

  Future<void> _ensureColumn(Database db, String tableName, String columnName, String columnDefinition) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final alreadyExists = columns.any((column) => column['name'] == columnName);
    if (!alreadyExists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(store_settings)');
      final hasCreatedAt = columns.any((column) => column['name'] == 'created_at');

      if (!hasCreatedAt) {
        await db.execute('ALTER TABLE store_settings ADD COLUMN created_at TEXT DEFAULT ""');
      }

      final row = await db.query('store_settings', where: 'id = ?', whereArgs: [1], limit: 1);
      if (row.isNotEmpty && (row.first['created_at'] == null || (row.first['created_at'] as String).isEmpty)) {
        final now = DateTime.now().toIso8601String();
        await db.update(
          'store_settings',
          {'created_at': now},
          where: 'id = ?',
          whereArgs: [1],
        );
      }
    }

    await _ensureColumn(db, 'products', 'name_ar', 'TEXT');
    await _ensureColumn(db, 'products', 'description', 'TEXT');
    await _ensureColumn(db, 'products', 'category_id', 'INTEGER');
    await _ensureColumn(db, 'products', 'brand_id', 'INTEGER');
    await _ensureColumn(db, 'products', 'unit_id', 'INTEGER');
    await _ensureColumn(db, 'products', 'purchase_price', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'selling_price', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'wholesale_price', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'retail_price', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'discount_price', 'REAL');
    await _ensureColumn(db, 'products', 'vat_rate', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'tax_rate', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'stock_quantity', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'min_stock', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'max_stock', 'REAL DEFAULT 0');
    await _ensureColumn(db, 'products', 'expiry_date', 'TEXT');
    await _ensureColumn(db, 'products', 'manufacturing_date', 'TEXT');
    await _ensureColumn(db, 'products', 'image_path', 'TEXT');
    await _ensureColumn(db, 'products', 'is_active', 'INTEGER DEFAULT 1');
    await _ensureColumn(db, 'products', 'allow_fractional', 'INTEGER DEFAULT 0');
    await _ensureColumn(db, 'products', 'created_at', 'TEXT NOT NULL DEFAULT ""');
    await _ensureColumn(db, 'products', 'updated_at', 'TEXT NOT NULL DEFAULT ""');

    final adminHash = sha256.convert(utf8.encode('admin123')).toString();
    final adminUsers = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
      limit: 1,
    );

    if (adminUsers.isNotEmpty) {
      final currentHash = adminUsers.first['password_hash'] as String?;
      if (currentHash == null || currentHash != adminHash) {
        await db.update(
          'users',
          {'password_hash': adminHash},
          where: 'username = ?',
          whereArgs: ['admin'],
        );
      }
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final String path = join(documentsDir.path, _dbName);
    await databaseFactory.deleteDatabase(path);
  }
}
