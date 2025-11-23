part of 'image_picker_bloc.dart';

abstract class ImagePickerEvent {}

class ImagePickerCameraRequested extends ImagePickerEvent {}

class ImagePickerGalleryRequested extends ImagePickerEvent {}

class ImagePickerImageSelected extends ImagePickerEvent {
  final String base64Image;

  ImagePickerImageSelected(this.base64Image);
}

class ImagePickerErrorOccurred extends ImagePickerEvent {
  final String message;

  ImagePickerErrorOccurred(this.message);
}

class ImagePickerHistoryRequested extends ImagePickerEvent {}