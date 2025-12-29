part of 'image_picker_bloc.dart';

abstract class ImagePickerState {
  const ImagePickerState();
}

class ImagePickerInitial extends ImagePickerState {}

class ImagePickerLoading extends ImagePickerState {}

class ImagePickerCaptureSuccess extends ImagePickerState {
  final String base64Image;
  final AnalysisResultEntity analysisResult;

  const ImagePickerCaptureSuccess({
    required this.base64Image,
    required this.analysisResult,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImagePickerCaptureSuccess &&
        other.base64Image == base64Image &&
        other.analysisResult == analysisResult;
  }

  @override
  int get hashCode => base64Image.hashCode ^ analysisResult.hashCode;
}

class ImagePickerHistoryLoaded extends ImagePickerState {
  final List<AnalysisEntity> history;

  const ImagePickerHistoryLoaded({required this.history});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImagePickerHistoryLoaded &&
        listEquals(other.history, history);
  }

  @override
  int get hashCode => history.hashCode;
}

class ImagePickerError extends ImagePickerState {
  final String message;

  const ImagePickerError({required this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImagePickerError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}