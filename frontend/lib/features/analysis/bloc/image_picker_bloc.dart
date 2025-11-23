import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

part 'image_picker_event.dart';
part 'image_picker_state.dart';

class ImagePickerBloc extends Bloc<ImagePickerEvent, ImagePickerState> {
  final ImagePicker _imagePicker = ImagePicker();

  ImagePickerBloc() : super(ImagePickerInitial()) {
    on<ImagePickerCameraRequested>(_onCameraRequested);
    on<ImagePickerGalleryRequested>(_onGalleryRequested);
    on<ImagePickerImageSelected>(_onImageSelected);
    on<ImagePickerErrorOccurred>(_onErrorOccurred);
    on<ImagePickerHistoryRequested>(_onHistoryRequested);
  }

  Future<void> _onCameraRequested(
    ImagePickerCameraRequested event,
    Emitter<ImagePickerState> emit,
  ) async {
    emit(ImagePickerLoading());
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        emit(ImagePickerCaptureSuccess(base64Image));
      } else {
        emit(const ImagePickerReady(historyCount: 2));
      }
    } catch (e) {
      emit(ImagePickerError('Ошибка при съемке фото: ${e.toString()}'));
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        emit(ImagePickerCaptureSuccess(base64Image));
      } else {
        emit(const ImagePickerReady(historyCount: 2));
      }
    } catch (e) {
      emit(ImagePickerError('Ошибка при выборе фото: ${e.toString()}'));
    }
  }

  Future<void> _onImageSelected(
    ImagePickerImageSelected event,
    Emitter<ImagePickerState> emit,
  ) async {
    emit(ImagePickerCaptureSuccess(event.base64Image));
  }

  Future<void> _onErrorOccurred(
    ImagePickerErrorOccurred event,
    Emitter<ImagePickerState> emit,
  ) async {
    emit(ImagePickerError(event.message));
  }

  Future<void> _onHistoryRequested(
    ImagePickerHistoryRequested event,
    Emitter<ImagePickerState> emit,
  ) async {
    // Можно добавить логику загрузки реального количества анализов
    emit(const ImagePickerReady(historyCount: 2));
  }
}