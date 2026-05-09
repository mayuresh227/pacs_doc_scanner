  import 'dart:io';
  import 'dart:typed_data';
  import 'package:image/image.dart' as img;
  import 'package:path_provider/path_provider.dart';

class AdaptiveCompressionService {
  static const int maxWidth = 800;
  static const int initialQuality = 90;
  static const int minQuality = 20;
  static const int qualityStep = 10;
  static const int targetSizeBytes = 500 * 1024; // 500KB target

  Future<File?> compressAdaptive(File file, {bool applyGrayscale = true}) async {
    try {
      final bytes = await file.readAsBytes();
      final compressed = await _adaptiveCompress(bytes, applyGrayscale: applyGrayscale);
      
      if (compressed == null) return null;

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File('${directory.path}/compressed_$timestamp.jpg');
      await compressedFile.writeAsBytes(compressed);

      return compressedFile;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> compressAdaptiveBytes(Uint8List bytes, {bool applyGrayscale = true}) async {
    return await _adaptiveCompress(bytes, applyGrayscale: applyGrayscale);
  }

  Future<Uint8List?> _adaptiveCompress(Uint8List bytes, {bool applyGrayscale = true}) async {
    // Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    // Apply grayscale if requested (reduces size significantly)
    if (applyGrayscale) {
      image = img.grayscale(image);
    }

    // Resize if width exceeds max
    if (image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }

    // Start compression loop
    int quality = initialQuality;
    Uint8List? result;

    while (quality >= minQuality) {
      result = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      
      if (result.length <= targetSizeBytes) {
        break;
      }

      quality -= qualityStep;
    }

    // If still too large at minimum quality, return what we have
    return result;
  }

  Future<Uint8List?> compressWithTargetSize(
    Uint8List bytes, {
    int targetSizeKB = 500,
    bool applyGrayscale = true,
  }) async {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    if (applyGrayscale) {
      image = img.grayscale(image);
    }

    if (image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }

    final targetBytes = targetSizeKB * 1024;
    int quality = initialQuality;
    Uint8List? result;

    while (quality >= minQuality) {
      result = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      
      if (result.length <= targetBytes) {
        break;
      }

      quality -= qualityStep;
    }

    return result;
  }
}