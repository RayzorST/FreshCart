part of 'image_picker_bloc.dart';

abstract class ImagePickerEvent {
  const ImagePickerEvent();
}

class ImagePickerCameraRequested extends ImagePickerEvent {
  const ImagePickerCameraRequested();
}

class ImagePickerGalleryRequested extends ImagePickerEvent {
  const ImagePickerGalleryRequested();
}

class ImagePickerHistoryRequested extends ImagePickerEvent {
  const ImagePickerHistoryRequested();
}

class ImagePickerClear extends ImagePickerEvent {
  const ImagePickerClear();
}