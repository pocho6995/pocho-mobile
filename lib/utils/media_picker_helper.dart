import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Безопасный выбор фото: на iOS камера падает, если открыть её
/// во время закрытия bottom sheet / без usage description.
class MediaPickerHelper {
  MediaPickerHelper._();

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickImage({
    required ImageSource source,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // Дать модалке закрыться, иначе UIImagePickerController крашит iOS.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('MediaPickerHelper.pickImage: $e');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('MediaPickerHelper.pickImage: $e');
      }
      return null;
    }
  }

  static Future<XFile?> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
  }) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('MediaPickerHelper.pickVideo: $e');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('MediaPickerHelper.pickVideo: $e');
      }
      return null;
    }
  }
}
