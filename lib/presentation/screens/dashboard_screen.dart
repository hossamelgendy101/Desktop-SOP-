import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/locale_service.dart';
import '../blocs/dashboard_bloc.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    return BlocProvider(
      create: (context) => DashboardBloc(
        saleRepository: context.read(),
        productRepository: context.read(),
      )..add(LoadDashboard()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(localeService.localize('Dashboard', 'لوحة التحكم')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<DashboardBloc>().add(LoadDashboard()),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DashboardError) {
              return Center(child: Text('${localeService.localize('Error', 'خطأ')}: ${state.message}'));
            }
            if (state is DashboardLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1200
                            ? 4
                            : constraints.maxWidth > 800
                                ? 2
                                : 1;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                          children: [
                            StatCard(
                              title: localeService.localize('Today\'s Sales', 'مبيعات اليوم'),
                              value: '\$${(state.todayStats['total'] as num).toStringAsFixed(2)}',
                              subtitle: '${state.todayStats['count']} ${localeService.localize('invoices', 'فواتير')}',
                              icon: Icons.attach_money,
                              color: Colors.green,
                              trend: '+12%',
                            ),
                            StatCard(
                              title: localeService.localize('Weekly Sales', 'المبيعات الأسبوعية'),
                              value: '\$${(state.weekStats['total'] as num).toStringAsFixed(2)}',
                              subtitle: localeService.localize('Last 7 days', 'آخر 7 أيام'),
                              icon: Icons.calendar_today,
                              color: Colors.blue,
                              trend: '+5%',
                            ),
                            StatCard(
                              title: localeService.localize('Low Stock Items', 'منتجات منخفضة المخزون'),
                              value: '${state.lowStockCount}',
                              subtitle: localeService.localize('Need restocking', 'تحتاج إعادة التوريد'),
                              icon: Icons.warning_amber,
                              color: Colors.orange,
                            ),
                            StatCard(
                              title: localeService.localize('Today\'s Profit', 'ربح اليوم'),
                              value: '\$${state.todayProfit.toStringAsFixed(2)}',
                              subtitle: localeService.localize('Estimated margin', 'هامش تقديري'),
                              icon: Icons.trending_up,
                              color: Colors.purple,
                              trend: '+8%',
                            ),
                          ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 1000;
                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isWide ? 2 : 0,
                              child: _buildSalesChart(context, state, localeService),
                            ),
                            if (isWide) const SizedBox(width: 24),
                            if (!isWide) const SizedBox(height: 24),
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildTopProducts(context, state, localeService),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    if (state.expiredCount > 0)
                      _buildAlertCard(
                        context,
                        localeService.localize('Expired Products', 'منتجات منتهية الصلاحية'),
                        '${state.expiredCount} ${localeService.localize('products have expired. Please review inventory.', 'منتج منتهي الصلاحية. يرجى مراجعة المخزون.')}',
                        Colors.red,
                        localeService,
                      ),
                    if (state.lowStockCount > 0)
                      _buildAlertCard(
                        context,
                        localeService.localize('Low Stock Alert', 'تنبيه مخزون منخفض'),
                        '${state.lowStockCount} ${localeService.localize('products are running low on stock.', 'منتجات تقترب من النفاد.')}',
                        Colors.orange,
                        localeService,
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, DashboardLoaded state, LocaleService localeService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localeService.localize('Sales Overview', 'نظرة عامة على المبيعات'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (state.weekStats['total'] as num).toDouble() * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() < days.length) {
                            return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 11));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (state.todayStats['total'] as num).toDouble() * (0.5 + index * 0.1),
                          color: const Color(0xFF2563EB),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context, DashboardLoaded state, LocaleService localeService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localeService.localize('Top Selling Products', 'أفضل المنتجات مبيعاً'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...state.topProducts.take(5).map((product) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                  child: Text(
                    (product['name'] as String).substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${product['total_qty']} ${localeService.localize('sold', 'تم بيعها')}'),
                trailing: Text(
                  '\$${(product['total_revenue'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, String title, String message, Color color, LocaleService localeService) {
    return Card(
      color: color.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        subtitle: Text(message, style: TextStyle(color: color.withOpacity(0.8))),
        trailing: TextButton(
          onPressed: () {},
          child: Text(localeService.localize('View', 'عرض'), style: TextStyle(color: color)),
        ),
      ),
    ).animate().shake(duration: 500.ms);
  }
}
