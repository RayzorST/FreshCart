import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:client/domain/entities/analysis_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/domain/repositories/analysis_repository.dart';
import 'package:client/domain/entities/analysis_result_entity.dart';
part 'image_picker_event.dart';
part 'image_picker_state.dart';

class ImagePickerBloc extends Bloc<ImagePickerEvent, ImagePickerState> {
  final AnalysisRepository _analysisRepository;
  final ImagePicker _imagePicker;

  ImagePickerBloc({required AnalysisRepository analysisRepository})
      : _analysisRepository = analysisRepository,
        _imagePicker = ImagePicker(),
        super(ImagePickerInitial()) {
    on<ImagePickerCameraRequested>(_onCameraRequested);
    on<ImagePickerGalleryRequested>(_onGalleryRequested);
    on<ImagePickerHistoryRequested>(_onHistoryRequested);
    on<ImagePickerClear>(_onClear);
  }

  Future<void> _onCameraRequested(
    ImagePickerCameraRequested event,
    Emitter<ImagePickerState> emit,
  ) async {
    emit(ImagePickerLoading());
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        emit(ImagePickerInitial());
        return;
      }

      // Читаем файл
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Анализируем изображение
      final result = await _analysisRepository.analyzeFoodImage(base64Image);
      
      await result.fold(
        (error) async {
          emit(ImagePickerError(message: error));
        },
        (analysisResult) async {
          // Сохраняем результат с изображением
          emit(ImagePickerCaptureSuccess(
            base64Image: base64Image,
            analysisResult: analysisResult,
          ));
        },
      );
    } catch (e) {
      emit(ImagePickerError(message: 'Ошибка при съемке фото: $e'));
    }
  }

  Future<void> _onGalleryRequested(
    ImagePickerGalleryRequested event,
    Emitter<ImagePickerState> emit,
  ) async {
    emit(ImagePickerLoading());
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        emit(ImagePickerInitial());
        return;
      }

      // Читаем файл
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Анализируем изображение
      final result = await _analysisRepository.analyzeFoodImage(base64Image);
      
      await result.fold(
        (error) async {
          emit(ImagePickerError(message: error));
        },
        (analysisResult) async {
          // Сохраняем результат с изображением
          emit(ImagePickerCaptureSuccess(
            base64Image: base64Image,
            analysisResult: analysisResult,
          ));
        },
      );
    } catch (e) {
      emit(ImagePickerError(message: 'Ошибка при выборе фото: $e'));
    }
  }

  Future<void> _onHistoryRequested(
    ImagePickerHistoryRequested event,
    Emitter<ImagePickerState> emit,
  ) async {
    emit(ImagePickerLoading());
    
    try {
      final result = await _analysisRepository.getMyAnalysisHistory();
      
      result.fold(
        (error) {
          emit(ImagePickerError(message: error));
        },
        (history) {
          emit(ImagePickerHistoryLoaded(history: history));
        },
      );
    } catch (e) {
      emit(ImagePickerError(message: 'Ошибка загрузки истории: $e'));
    }
  }

  Future<void> _onClear(
    ImagePickerClear event,
    Emitter<ImagePickerState> emit,
  ) async {
    emit(ImagePickerInitial());
  }
}