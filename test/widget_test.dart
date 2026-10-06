import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database/db_helper.dart';
import 'package:pos_system/data/repositories/user_repository.dart';

void main() {
  testWidgets('admin login works with admin123', (WidgetTester tester) async {
    await DatabaseHelper().deleteDatabase();
    final repo = UserRepository();
    final user = await repo.authenticate('admin', 'admin123');
    expect(user, isNotNull);
    expect(user?.username, 'admin');
  });
}
