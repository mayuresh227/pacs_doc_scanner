import 'dart:typed_data';
import 'package:image/image.dart' as img;

enum EnhancementMode {
  original,
  grayscale,
  blackAndWhite,
}

class ImageEnhancementService {
  Future<Uint8List?> enhanceImage({
    required Uint8List imageBytes,
    required EnhancementMode mode,
    double contrast = 1.2,
    double brightness = 1.0,
    int thresholdValue = 128,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      img.Image processed;

      switch (mode) {
        case EnhancementMode.original:
          processed = image;
          break;
        case EnhancementMode.grayscale:
          processed = _applyGrayscale(image);
          break;
        case EnhancementMode.blackAndWhite:
          processed = _applyGrayscale(image);
          processed = _applyThreshold(processed, thresholdValue);
          break;
      }

      // Apply contrast enhancement (skip for original mode)
      if (mode != EnhancementMode.original && contrast != 1.0) {
        processed = _applyContrast(processed, contrast);
      }

      // Apply brightness correction (skip for original mode)
      if (mode != EnhancementMode.original && brightness != 1.0) {
        processed = _applyBrightness(processed, brightness);
      }

      return Uint8List.fromList(img.encodeJpg(processed, quality: 90));
    } catch (e) {
      return null;
    }
  }

  img.Image _applyGrayscale(img.Image image) {
    return img.grayscale(image);
  }

  img.Image _applyThreshold(img.Image image, int threshold) {
    final grayscale = img.grayscale(image);
    
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        
        if (luminance > threshold) {
          grayscale.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        } else {
          grayscale.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }
    
    return grayscale;
  }

  img.Image _applyContrast(img.Image image, double factor) {
    return img.contrast(image, contrast: (factor * 100).toInt());
  }

  img.Image _applyBrightness(img.Image image, double factor) {
    final adjustment = ((factor - 1.0) * 100).toInt();
    return img.adjustColor(image, brightness: adjustment.toDouble());
  }

  Future<Uint8List?> autoEnhance(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Convert to grayscale
      var processed = img.grayscale(image);

      // Apply contrast
      processed = img.contrast(processed, contrast: 120);

      // Apply unsharp mask for sharpening
      processed = img.convolution(processed, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ]);

      // Apply threshold for B&W
      for (int y = 0; y < processed.height; y++) {
        for (int x = 0; x < processed.width; x++) {
          final pixel = processed.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          
          if (luminance > 128) {
            processed.setPixel(x, y, img.ColorRgb8(255, 255, 255));
          } else {
            processed.setPixel(x, y, img.ColorRgb8(0, 0, 0));
          }
        }
      }

      return Uint8List.fromList(img.encodeJpg(processed, quality: 90));
    } catch (e) {
      return null;
    }
  }
}