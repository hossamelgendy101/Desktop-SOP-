import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/sale_repository.dart';
import '../../data/repositories/product_repository.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> todayStats;
  final Map<String, dynamic> weekStats;
  final Map<String, dynamic> monthStats;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> lowStock;
  final List<Map<String, dynamic>> recentSales;
  final double todayProfit;
  final int lowStockCount;
  final int expiredCount;

  const DashboardLoaded({
    required this.todayStats,
    required this.weekStats,
    required this.monthStats,
    required this.topProducts,
    required this.lowStock,
    required this.recentSales,
    required this.todayProfit,
    required this.lowStockCount,
    required this.expiredCount,
  });

  @override
  List<Object?> get props => [
        todayStats, weekStats, monthStats, topProducts,
        lowStock, recentSales, todayProfit, lowStockCount, expiredCount
      ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;

  DashboardBloc({
    required SaleRepository saleRepository,
    required ProductRepository productRepository,
  })  : _saleRepository = saleRepository,
        _productRepository = productRepository,
        super(DashboardLoading()) {
    on<LoadDashboard>(_onLoadDashboard);
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final todayStats = await _saleRepository.getSalesSummary(period: 'today');
      final weekStats = await _saleRepository.getSalesSummary(period: 'week');
      final monthStats = await _saleRepository.getSalesSummary(period: 'month');
      final topProducts = await _productRepository.getTopSelling(limit: 5, period: 'today');
      final lowStock = await _productRepository.getLowStock();
      final expired = await _productRepository.getExpiredProducts();

      final todayProfit = (todayStats['total'] as num).toDouble() * 0.2;

      emit(DashboardLoaded(
        todayStats: todayStats,
        weekStats: weekStats,
        monthStats: monthStats,
        topProducts: topProducts,
        lowStock: lowStock.map((p) => p.toMap()).toList(),
        recentSales: [],
        todayProfit: todayProfit,
        lowStockCount: lowStock.length,
        expiredCount: expired.length,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
