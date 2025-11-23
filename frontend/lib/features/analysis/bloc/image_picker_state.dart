part of 'image_picker_bloc.dart';

abstract class ImagePickerState {
  const ImagePickerState();
}

class ImagePickerInitial extends ImagePickerState {}

class ImagePickerLoading extends ImagePickerState {}

class ImagePickerCaptureSuccess extends ImagePickerState {
  final String base64Image;

  const ImagePickerCaptureSuccess(this.base64Image);
}

class ImagePickerError extends ImagePickerState {
  final String message;

  const ImagePickerError(this.message);
}

class ImagePickerReady extends ImagePickerState {
  final int historyCount;

  const ImagePickerReady({this.historyCount = 0});
}