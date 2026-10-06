import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {}
class SearchProducts extends ProductEvent {
  final String query;
  const SearchProducts(this.query);
}
class AddProduct extends ProductEvent {
  final ProductModel product;
  const AddProduct(this.product);
}
class UpdateProduct extends ProductEvent {
  final ProductModel product;
  const UpdateProduct(this.product);
}
class DeleteProduct extends ProductEvent {
  final int id;
  const DeleteProduct(this.id);
}

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  const ProductLoaded(this.products);
  @override
  List<Object?> get props => [products];
}
class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc({required ProductRepository repository})
      : _repository = repository,
        super(ProductInitial()) {
    on<LoadProducts>(_onLoad);
    on<SearchProducts>(_onSearch);
    on<AddProduct>(_onAdd);
    on<UpdateProduct>(_onUpdate);
    on<DeleteProduct>(_onDelete);
  }

  Future<void> _onLoad(LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await _repository.getAll(limit: 100);
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onSearch(SearchProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await _repository.searchProducts(event.query);
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onAdd(AddProduct event, Emitter<ProductState> emit) async {
    try {
      await _repository.insert(event.product);
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateProduct event, Emitter<ProductState> emit) async {
    try {
      await _repository.update(event.product);
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteProduct event, Emitter<ProductState> emit) async {
    try {
      await _repository.delete(event.id);
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
