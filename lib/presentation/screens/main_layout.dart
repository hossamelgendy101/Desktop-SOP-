import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/locale_service.dart';
import '../blocs/auth_bloc.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'sales_history_screen.dart';
import 'customers_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const PosScreen(),
    const ProductsScreen(),
    const SalesHistoryScreen(),
    const CustomersScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final translatedItems = [
      NavigationItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: localeService.localize('Dashboard', 'لوحة التحكم')),
      NavigationItem(icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale, label: localeService.localize('POS', 'نقطة البيع')),
      NavigationItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: localeService.localize('Products', 'المنتجات')),
      NavigationItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: localeService.localize('Sales', 'المبيعات')),
      NavigationItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: localeService.localize('Customers', 'العملاء')),
      NavigationItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: localeService.localize('Settings', 'الإعدادات')),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1200,
              minExtendedWidth: 220,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              leading: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.point_of_sale_rounded, color: Color(0xFF2563EB), size: 32),
                    if (MediaQuery.of(context).size.width > 1200) ...[
                      const SizedBox(width: 12),
                      Text(
                        'ProPOS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                tooltip: localeService.localize('Logout', 'تسجيل الخروج'),
              ),
              destinations: translatedItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                );
              }).toList(),
            ),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: translatedItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                );
              }).toList(),
            )
          : null,
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  NavigationItem({required this.icon, required this.selectedIcon, required this.label});
}
