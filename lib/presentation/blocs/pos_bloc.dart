import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/sale_repository.dart';

class CartItem {
  final ProductModel product;
  double quantity;
  double discount;
  String? note;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
    this.note,
  });

  double get unitPrice => product.finalPrice;
  double get subtotal => unitPrice * quantity;
  double get totalDiscount => discount * quantity;
  double get total => subtotal - totalDiscount;
}

abstract class PosEvent extends Equatable {
  const PosEvent();
  @override
  List<Object?> get props => [];
}

class ScanBarcode extends PosEvent {
  final String barcode;
  const ScanBarcode(this.barcode);
}

class SearchProduct extends PosEvent {
  final String query;
  const SearchProduct(this.query);
}

class AddToCart extends PosEvent {
  final ProductModel product;
  final double? quantity;
  const AddToCart(this.product, {this.quantity});
}

class UpdateCartQuantity extends PosEvent {
  final int productId;
  final double quantity;
  const UpdateCartQuantity(this.productId, this.quantity);
}

class RemoveFromCart extends PosEvent {
  final int productId;
  const RemoveFromCart(this.productId);
}

class ApplyDiscount extends PosEvent {
  final double discount;
  final bool isPercentage;
  const ApplyDiscount(this.discount, {this.isPercentage = true});
}

class SetTaxRate extends PosEvent {
  final double taxRate;
  const SetTaxRate(this.taxRate);
}

class ApplyCoupon extends PosEvent {
  final String couponCode;
  const ApplyCoupon(this.couponCode);
}

class SetCustomer extends PosEvent {
  final int? customerId;
  const SetCustomer(this.customerId);
}

class SetPaymentMethod extends PosEvent {
  final String method;
  const SetPaymentMethod(this.method);
}

class ProcessPayment extends PosEvent {
  final double paidAmount;
  final String? notes;
  const ProcessPayment(this.paidAmount, {this.notes});
}

class ClearCart extends PosEvent {}

class HoldInvoice extends PosEvent {
  final String? name;
  const HoldInvoice({this.name});
}

abstract class PosState extends Equatable {
  const PosState();
  @override
  List<Object?> get props => [];
}

class PosInitial extends PosState {}

class PosLoading extends PosState {}

class PosReady extends PosState {
  final List<CartItem> cart;
  final List<ProductModel> searchResults;
  final int? customerId;
  final String paymentMethod;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double subtotal;
  final double grandTotal;
  final double paidAmount;
  final double changeAmount;
  final String? error;
  final bool isProcessing;
  final SaleModel? lastSale;

  const PosReady({
    this.cart = const [],
    this.searchResults = const [],
    this.customerId,
    this.paymentMethod = 'cash',
    this.discountAmount = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.subtotal = 0,
    this.grandTotal = 0,
    this.paidAmount = 0,
    this.changeAmount = 0,
    this.error,
    this.isProcessing = false,
    this.lastSale,
  });

  PosReady copyWith({
    List<CartItem>? cart,
    List<ProductModel>? searchResults,
    int? customerId,
    String? paymentMethod,
    double? discountAmount,
    double? taxRate,
    double? taxAmount,
    double? subtotal,
    double? grandTotal,
    double? paidAmount,
    double? changeAmount,
    String? error,
    bool? isProcessing,
    SaleModel? lastSale,
    bool clearLastSale = false,
  }) {
    return PosReady(
      cart: cart ?? this.cart,
      searchResults: searchResults ?? this.searchResults,
      customerId: customerId ?? this.customerId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      error: error,
      isProcessing: isProcessing ?? this.isProcessing,
      lastSale: clearLastSale ? null : (lastSale ?? this.lastSale),
    );
  }

  @override
  List<Object?> get props => [
        cart, searchResults, customerId, paymentMethod,
        discountAmount, taxRate, taxAmount, subtotal, grandTotal,
        paidAmount, changeAmount, error, isProcessing, lastSale,
      ];
}

class PosError extends PosState {
  final String message;
  const PosError(this.message);
  @override
  List<Object?> get props => [message];
}

class PosBloc extends Bloc<PosEvent, PosState> {
  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;
  final int _cashierId;
  final int? _warehouseId;

  PosBloc({
    required ProductRepository productRepository,
    required SaleRepository saleRepository,
    required int cashierId,
    int? warehouseId,
  })  : _productRepository = productRepository,
        _saleRepository = saleRepository,
        _cashierId = cashierId,
        _warehouseId = warehouseId ?? 1,
        super(PosReady()) {
    on<ScanBarcode>(_onScanBarcode);
    on<SearchProduct>(_onSearchProduct);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartQuantity>(_onUpdateCartQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ApplyDiscount>(_onApplyDiscount);
    on<SetTaxRate>(_onSetTaxRate);
    on<SetCustomer>(_onSetCustomer);
    on<SetPaymentMethod>(_onSetPaymentMethod);
    on<ProcessPayment>(_onProcessPayment);
    on<ClearCart>(_onClearCart);
    on<HoldInvoice>(_onHoldInvoice);
  }

  Future<void> _onScanBarcode(ScanBarcode event, Emitter<PosState> emit) async {
    emit((state as PosReady).copyWith(isProcessing: true));
    try {
      final product = await _productRepository.getByBarcode(event.barcode);
      if (product != null && product.isActive) {
        add(AddToCart(product));
        emit((state as PosReady).copyWith(isProcessing: false, error: null));
      } else {
        emit((state as PosReady).copyWith(
          error: 'Product not found: ${event.barcode}',
          isProcessing: false,
        ));
      }
    } catch (e) {
      emit((state as PosReady).copyWith(error: e.toString(), isProcessing: false));
    }
  }

  Future<void> _onSearchProduct(SearchProduct event, Emitter<PosState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      final allProducts = await _productRepository.getAll(limit: 100);
      emit((state as PosReady).copyWith(searchResults: allProducts, error: null));
      return;
    }

    final results = await _productRepository.searchProducts(query);
    emit((state as PosReady).copyWith(searchResults: results, error: null));
  }

  void _onAddToCart(AddToCart event, Emitter<PosState> emit) {
    final current = state as PosReady;
    final existingIndex = current.cart.indexWhere((item) => item.product.id == event.product.id);

    List<CartItem> newCart = List.from(current.cart);
    if (existingIndex >= 0) {
      newCart[existingIndex] = CartItem(
        product: event.product,
        quantity: newCart[existingIndex].quantity + (event.quantity ?? 1),
        discount: newCart[existingIndex].discount,
      );
    } else {
      newCart.add(CartItem(product: event.product, quantity: event.quantity ?? 1));
    }

    _emitCalculatedState(emit, current.copyWith(cart: newCart, error: null));
  }

  void _onUpdateCartQuantity(UpdateCartQuantity event, Emitter<PosState> emit) {
    final current = state as PosReady;
    final newCart = current.cart.map((item) {
      if (item.product.id == event.productId) {
        return CartItem(product: item.product, quantity: event.quantity, discount: item.discount);
      }
      return item;
    }).where((item) => item.quantity > 0).toList();

    _emitCalculatedState(emit, current.copyWith(cart: newCart));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<PosState> emit) {
    final current = state as PosReady;
    final newCart = current.cart.where((item) => item.product.id != event.productId).toList();
    _emitCalculatedState(emit, current.copyWith(cart: newCart));
  }

  void _onApplyDiscount(ApplyDiscount event, Emitter<PosState> emit) {
    final current = state as PosReady;
    double discount = event.discount;
    if (event.isPercentage) {
      discount = (current.subtotal * (event.discount / 100)).toDouble();
    }
    _emitCalculatedState(emit, current.copyWith(discountAmount: discount));
  }

  void _onSetTaxRate(SetTaxRate event, Emitter<PosState> emit) {
    final current = state as PosReady;
    final double safeRate = event.taxRate < 0 ? 0.0 : event.taxRate;
    _emitCalculatedState(emit, current.copyWith(taxRate: safeRate));
  }

  void _onSetCustomer(SetCustomer event, Emitter<PosState> emit) {
    final current = state as PosReady;
    emit(current.copyWith(customerId: event.customerId));
  }

  void _onSetPaymentMethod(SetPaymentMethod event, Emitter<PosState> emit) {
    final current = state as PosReady;
    emit(current.copyWith(paymentMethod: event.method));
  }

  Future<void> _onProcessPayment(ProcessPayment event, Emitter<PosState> emit) async {
    final current = state as PosReady;
    if (current.cart.isEmpty) {
      emit(current.copyWith(error: 'Cart is empty', isProcessing: false));
      return;
    }

    if (event.paidAmount < current.grandTotal) {
      emit(current.copyWith(error: 'Paid amount is less than total', isProcessing: false));
      return;
    }

    emit(current.copyWith(isProcessing: true, error: null));

    try {
      final now = DateTime.now();
      final invoiceNumber = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final items = current.cart.map((cartItem) => SaleItemModel(
        saleId: 0,
        productId: cartItem.product.id!,
        quantity: cartItem.quantity,
        unitPrice: cartItem.unitPrice,
        discount: cartItem.discount,
        tax: 0,
        total: cartItem.total,
        costPrice: cartItem.product.purchasePrice,
      )).toList();

      final sale = SaleModel(
        invoiceNumber: invoiceNumber,
        customerId: current.customerId,
        warehouseId: _warehouseId,
        subtotal: current.subtotal,
        discountAmount: current.discountAmount,
        taxAmount: current.taxAmount,
        grandTotal: current.grandTotal,
        paidAmount: event.paidAmount,
        changeAmount: event.paidAmount - current.grandTotal,
        paymentMethod: current.paymentMethod,
        paymentStatus: event.paidAmount >= current.grandTotal ? 'paid' : 'partial',
        saleDate: now,
        cashierId: _cashierId,
        notes: event.notes,
        createdAt: now,
      );

      final saleId = await _saleRepository.createSale(sale, items);
      final completedSale = await _saleRepository.getSaleWithItems(saleId);

      emit(PosReady(
        cart: [],
        customerId: null,
        paymentMethod: 'cash',
        discountAmount: 0,
        taxRate: current.taxRate,
        taxAmount: 0,
        subtotal: 0,
        grandTotal: 0,
        paidAmount: 0,
        changeAmount: 0,
        lastSale: completedSale,
      ));
    } catch (e) {
      emit(current.copyWith(error: 'Payment failed: $e', isProcessing: false));
    }
  }

  void _onClearCart(ClearCart event, Emitter<PosState> emit) {
    emit(const PosReady());
  }

  Future<void> _onHoldInvoice(HoldInvoice event, Emitter<PosState> emit) async {
    final current = state as PosReady;
    await _saleRepository.holdInvoice(
      {'items': current.cart.length},
      _cashierId,
      customerId: current.customerId,
      totalAmount: current.grandTotal,
      holdName: event.name,
    );
    emit(const PosReady());
  }

  void _emitCalculatedState(Emitter<PosState> emit, PosReady state) {
    final subtotal = state.cart.fold<double>(0, (sum, item) => sum + item.subtotal);
    final double discountAmount = subtotal > 0 ? state.discountAmount : 0.0;
    final double taxAmount = subtotal > 0
        ? ((subtotal - discountAmount) * (state.taxRate / 100)).toDouble()
        : 0.0;
    final grandTotal = subtotal - discountAmount + taxAmount;

    emit(state.copyWith(
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal > 0 ? grandTotal : 0,
      isProcessing: false,
      error: null,
    ));
  }
}
