  import 'dart:io';
  import 'dart:typed_data';
  import 'package:image/image.dart' as img;
  import 'package:path_provider/path_provider.dart';
  import '../../core/constants/app_constants.dart';

class ImageProcessingService {
  Future<File?> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final result = await compressImageBytes(bytes);
      
      if (result == null) return null;

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File('${directory.path}/compressed_$timestamp.jpg');
      await compressedFile.writeAsBytes(result);

      return compressedFile;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> compressImageBytes(Uint8List bytes) async {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    // Resize if needed
    if (image.width > AppConstants.maxImageWidth || image.height > AppConstants.maxImageHeight) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? AppConstants.maxImageWidth : 0,
        height: image.height >= image.width ? AppConstants.maxImageHeight : 0,
      );
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: AppConstants.jpegQuality));
  }

  Future<File?> rotateImage(File file, int degrees) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return null;

    final rotated = img.copyRotate(image, angle: degrees.toDouble());

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rotatedFile = File('${directory.path}/rotated_${degrees}_$timestamp.jpg');
    await rotatedFile.writeAsBytes(img.encodeJpg(rotated, quality: AppConstants.jpegQuality));

    return rotatedFile;
  }

  Future<Uint8List?> rotateImageBytes(Uint8List bytes, int degrees) async {
    final image = img.decodeImage(bytes);

    if (image == null) return null;

    final rotated = img.copyRotate(image, angle: degrees.toDouble());
    return Uint8List.fromList(img.encodeJpg(rotated, quality: AppConstants.jpegQuality));
  }

  Future<File?> cropImage(
    File file, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return null;

    final cropped = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final croppedFile = File('${directory.path}/cropped_$timestamp.jpg');
    await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: AppConstants.jpegQuality));

    return croppedFile;
  }

  Future<Uint8List?> cropImageBytes(
    Uint8List bytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final image = img.decodeImage(bytes);

    if (image == null) return null;

    final cropped = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: AppConstants.jpegQuality));
  }
}