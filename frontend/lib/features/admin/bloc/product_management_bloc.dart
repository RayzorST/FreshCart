import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/entities/category_entity.dart';
import 'package:client/domain/entities/tag_entity.dart';
import 'package:client/domain/repositories/product_management_repository.dart';

part 'product_management_event.dart';
part 'product_management_state.dart';

class ProductManagementBloc extends Bloc<ProductManagementEvent, ProductManagementState> {
  final ProductManagementRepository repository;

  ProductManagementBloc({required this.repository}) : super(const ProductManagementInitial()) {
    on<LoadProductData>(_onLoadProductData);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<UploadProductImage>(_onUploadProductImage);
    on<ToggleProductActive>(_onToggleProductActive);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<UploadCategoryImage>(_onUploadCategoryImage);
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
    
    final result = await repository.loadProductData();
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (data) => emit(ProductManagementLoaded(
        products: data['products'] as List<ProductEntity>,
        categories: data['categories'] as List<CategoryEntity>,
        tags: data['tags'] as List<TagEntity>,
      )),
    );
  }

  Future<void> _onCreateProduct(
    CreateProduct event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.createProduct(event.productData);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Товар создан'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.updateProduct(event.productId, event.productData);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Товар обновлен'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onUploadProductImage(
    UploadProductImage event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      final result = await repository.uploadProductImage(
        event.productId,
        null,
        event.base64Image,
      );
      
      result.fold(
        (error) => emit(ProductManagementError(error)),
        (_) {
          emit(const ProductManagementOperationSuccess('Изображение товара загружено'));
          add(const LoadProductData());
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(ProductManagementError('Ошибка загрузки изображения товара: $e'));
      }
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.deleteProduct(event.productId);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Товар удален'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onToggleProductActive(
    ToggleProductActive event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.toggleProductActive(event.productId, event.isActive);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Статус товара изменен'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.createCategory(event.categoryData);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Категория создана'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.updateCategory(event.categoryId, event.categoryData);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Категория обновлена'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onUploadCategoryImage(
    UploadCategoryImage event,
    Emitter<ProductManagementState> emit,
  ) async {
    try {
      final result = await repository.uploadCategoryImage(
        event.categoryId,
        null,
        event.base64Image,
      );
      
      result.fold(
        (error) => emit(ProductManagementError(error)),
        (_) {
          emit(const ProductManagementOperationSuccess('Изображение категории загружено'));
          add(const LoadProductData());
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(ProductManagementError('Ошибка загрузки изображения: $e'));
      }
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.deleteCategory(event.categoryId);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Категория удалена'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onCreateTag(
    CreateTag event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.createTag(event.tagData);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Тег создан'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onUpdateTag(
    UpdateTag event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.updateTag(event.tagId, event.tagData);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Тег обновлен'));
        add(const LoadProductData());
      },
    );
  }

  Future<void> _onDeleteTag(
    DeleteTag event,
    Emitter<ProductManagementState> emit,
  ) async {
    final result = await repository.deleteTag(event.tagId);
    
    result.fold(
      (error) => emit(ProductManagementError(error)),
      (_) {
        emit(const ProductManagementOperationSuccess('Тег удален'));
        add(const LoadProductData());
      },
    );
  }
}