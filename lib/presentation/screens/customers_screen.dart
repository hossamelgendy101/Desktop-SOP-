import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/base_repository.dart';
import '../../services/locale_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repository = _CustomerRepository();
  List<CustomerModel> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await _repository.getAll();
    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(localeService.localize('Customers', 'العملاء')),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.file_download), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(customer.name.substring(0, 1).toUpperCase())),
                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customer.phone != null) Text(customer.phone!),
                        Text('${localeService.localize('Points', 'النقاط')}: ${customer.loyaltyPoints}'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${customer.balance.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: customer.balance > 0 ? Colors.red : Colors.green)),
                        Text(localeService.localize('Balance', 'الرصيد'), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: Text(localeService.localize('Add Customer', 'إضافة عميل')),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final localeService = context.read<LocaleService>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localeService.localize('Add Customer', 'إضافة عميل')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: localeService.localize('Name *', 'الاسم *'))),
            TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: localeService.localize('Phone', 'الهاتف'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localeService.localize('Cancel', 'إلغاء'))),
          ElevatedButton(
            onPressed: () async {
              final customer = CustomerModel(
                name: nameCtrl.text,
                phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                createdAt: DateTime.now(),
              );
              await _repository.insert(customer);
              if (context.mounted) Navigator.pop(context);
              _loadCustomers();
            },
            child: Text(localeService.localize('Save', 'حفظ')),
          ),
        ],
      ),
    );
  }
}

class _CustomerRepository extends BaseRepository<CustomerModel> {
  @override
  String get tableName => 'customers';
  @override
  CustomerModel fromMap(Map<String, dynamic> map) => CustomerModel.fromMap(map);
  @override
  Map<String, dynamic> toMap(CustomerModel item) => item.toMap();
}
