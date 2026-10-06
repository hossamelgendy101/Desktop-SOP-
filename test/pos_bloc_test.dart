import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database/db_helper.dart';
import 'package:pos_system/data/models/product_model.dart';
import 'package:pos_system/data/repositories/product_repository.dart';
import 'package:pos_system/data/repositories/sale_repository.dart';
import 'package:pos_system/presentation/blocs/pos_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await DatabaseHelper().deleteDatabase();
  });

  test('scan barcode should add product and reset processing flag', () async {
    final repo = ProductRepository();
    final saleRepo = SaleRepository();
    final now = DateTime.now();

    final product = ProductModel(
      name: 'Coffee',
      barcode: 'ABC-001',
      sku: 'SKU-001',
      sellingPrice: 25,
      purchasePrice: 15,
      wholesalePrice: 0,
      retailPrice: 25,
      stockQuantity: 10,
      minStock: 2,
      createdAt: now,
      updatedAt: now,
    );

    await repo.insert(product);

    final bloc = PosBloc(
      productRepository: repo,
      saleRepository: saleRepo,
      cashierId: 1,
    );

    bloc.add(const ScanBarcode('ABC-001'));

    await Future<void>.delayed(const Duration(milliseconds: 200));

    final state = bloc.state;
    expect(state, isA<PosReady>());
    final ready = state as PosReady;
    expect(ready.cart.length, 1);
    expect(ready.isProcessing, isFalse);
    expect(ready.error, isNull);
  });
}
