import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/api/client.dart';
import 'package:flutter/foundation.dart';

part 'product_management_event.dart';
part 'product_management_state.dart';

class ProductManagementBloc extends Bloc<ProductManagementEvent, ProductManagementState> {
  ProductManagementBloc() : super(const ProductManagementInitial()) {
    on<LoadProductData>(_onLoadProductData);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<ToggleProductActive>(_onToggleProductActive);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<CreateTag>(_onCreateTag);
    on<UpdateTag>(_onUpdateTag);
    on<DeleteTag>(_onDeleteTag);
  }

  Future<void> _onLoadProductData(
    LoadProductData event,
    Emitter<ProductManagementState> emit,
  ) async {
    emit(const ProductManagementLoading());
    
    try {
      final [products, categories, tags] = await Future.wait([
        ApiClient.getAdminProducts(includeInactive: true),
        ApiClient.getAdminCategories(),
        ApiClient.getAdminTags(),
      ]);
      
      emit(ProductManagementLoaded(
        products: products,
        categories: categories,
        tags: tags,
      ));
    } catch (e) {
      emit(ProductManagementError('Ошибка загрузки данных: $e'));
    }
  }

  Future<void> _onCreateProduct(
    CreateProduct event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.createAdminProduct(event.productData);
      emit(const ProductManagementOperationSuccess('Товар создан'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка создания товара: $e'));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.updateAdminProduct(event.productId, event.productData);
      emit(const ProductManagementOperationSuccess('Товар обновлен'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка обновления товара: $e'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.deleteAdminProduct(event.productId);
      emit(const ProductManagementOperationSuccess('Товар удален'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка удаления товара: $e'));
    }
  }

  Future<void> _onToggleProductActive(
    ToggleProductActive event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.updateAdminProduct(event.productId, {
        'is_active': event.isActive,
      });
      emit(const ProductManagementOperationSuccess('Статус товара изменен'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка изменения статуса товара: $e'));
    }
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.createAdminCategory(event.categoryData);
      emit(const ProductManagementOperationSuccess('Категория создана'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка создания категории: $e'));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.updateAdminCategory(event.categoryId, event.categoryData);
      emit(const ProductManagementOperationSuccess('Категория обновлена'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка обновления категории: $e'));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.deleteAdminCategory(event.categoryId);
      emit(const ProductManagementOperationSuccess('Категория удалена'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка удаления категории: $e'));
    }
  }

  Future<void> _onCreateTag(
    CreateTag event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.createAdminTag(event.tagData);
      emit(const ProductManagementOperationSuccess('Тег создан'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка создания тега: $e'));
    }
  }

  Future<void> _onUpdateTag(
    UpdateTag event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.updateAdminTag(event.tagId, event.tagData);
      emit(const ProductManagementOperationSuccess('Тег обновлен'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка обновления тега: $e'));
    }
  }

  Future<void> _onDeleteTag(
    DeleteTag event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      await ApiClient.deleteAdminTag(event.tagId);
      emit(const ProductManagementOperationSuccess('Тег удален'));
      add(const LoadProductData());
    } catch (e) {
      emit(ProductManagementError('Ошибка удаления тега: $e'));
    }
  }
}