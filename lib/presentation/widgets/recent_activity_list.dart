import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/locale_service.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localeService.localize('Recent Activity', 'النشاط الأخير'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(localeService.localize('Sale completed', 'تمت العملية بنجاح')),
              subtitle: const Text('INV-20260726-001 - \$150.00'),
              trailing: Text(localeService.localize('2m ago', 'منذ دقيقة')), 
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.blue),
              title: Text(localeService.localize('New product added', 'تمت إضافة منتج جديد')),
              subtitle: const Text('Wireless Mouse - SKU-001'),
              trailing: Text(localeService.localize('15m ago', 'منذ 15 دقيقة')),
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(localeService.localize('Low stock alert', 'تنبيه مخزون منخفض')),
              subtitle: const Text('Coca Cola 330ml - 3 remaining'),
              trailing: Text(localeService.localize('1h ago', 'منذ ساعة')),
            ),
          ],
        ),
      ),
    );
  }
}
