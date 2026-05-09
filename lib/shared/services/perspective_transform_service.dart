import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PerspectiveTransformService {
  Future<Uint8List?> applyPerspectiveTransform({
    required Uint8List imageBytes,
    required List<Point> corners,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Sort corners: top-left, top-right, bottom-right, bottom-left
      final sortedCorners = _sortCorners(corners);
      
      // Calculate the width and height of the output
      final topWidth = _distance(sortedCorners[0], sortedCorners[1]);
      final bottomWidth = _distance(sortedCorners[3], sortedCorners[2]);
      final leftHeight = _distance(sortedCorners[0], sortedCorners[3]);
      final rightHeight = _distance(sortedCorners[1], sortedCorners[2]);

      final outputWidth = math.max(topWidth, bottomWidth).toInt();
      final outputHeight = math.max(leftHeight, rightHeight).toInt();

      if (outputWidth <= 0 || outputHeight <= 0) return null;

      // Create output image
      final output = img.Image(width: outputWidth, height: outputHeight);

      // Source points
      final srcPoints = sortedCorners.map((p) => [p.x.toDouble(), p.y.toDouble()]).toList();
      
      // Destination points (rectangle)
      final dstPoints = [
        [0.0, 0.0],
        [outputWidth.toDouble(), 0.0],
        [outputWidth.toDouble(), outputHeight.toDouble()],
        [0.0, outputHeight.toDouble()],
      ];

      // Compute perspective transform matrix
      final matrix = _computePerspectiveTransform(srcPoints, dstPoints);

      // Apply transformation
      for (int y = 0; y < outputHeight; y++) {
        for (int x = 0; x < outputWidth; x++) {
          final src = _applyTransformMatrix(matrix, x.toDouble(), y.toDouble());
          
          final srcX = src[0].round();
          final srcY = src[1].round();

          if (srcX >= 0 && srcX < image.width && srcY >= 0 && srcY < image.height) {
            output.setPixel(x, y, image.getPixel(srcX, srcY));
          }
        }
      }

      return Uint8List.fromList(img.encodeJpg(output, quality: 90));
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> cropImage({
    required Uint8List imageBytes,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final cropped = img.copyCrop(
        image,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
    } catch (e) {
      return null;
    }
  }

  List<Point> _sortCorners(List<Point> corners) {
    // Find center
    double centerX = 0, centerY = 0;
    for (final corner in corners) {
      centerX += corner.x;
      centerY += corner.y;
    }
    centerX /= corners.length;
    centerY /= corners.length;

    // Sort by angle from center
    final sorted = List<Point>.from(corners);
    sorted.sort((a, b) {
      final angleA = math.atan2(a.y - centerY, a.x - centerX);
      final angleB = math.atan2(b.y - centerY, b.x - centerX);
      return angleA.compareTo(angleB);
    });

    // Ensure top-left is first
    double minSum = double.infinity;
    int minIndex = 0;
    for (int i = 0; i < sorted.length; i++) {
      final sum = sorted[i].x + sorted[i].y;
      if (sum < minSum) {
        minSum = sum;
        minIndex = i;
      }
    }

    // Rotate so top-left is first
    if (minIndex > 0) {
      final rotated = <Point>[];
      rotated.addAll(sorted.sublist(minIndex));
      rotated.addAll(sorted.sublist(0, minIndex));
      return rotated;
    }

    return sorted;
  }

  double _distance(Point p1, Point p2) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  List<List<double>> _computePerspectiveTransform(
    List<List<double>> src,
    List<List<double>> dst,
  ) {
    // Compute transformation matrix using least squares
    final a = <List<double>>[];
    final b = <List<double>>[];

    for (int i = 0; i < 4; i++) {
      final x = src[i][0];
      final y = src[i][1];
      final u = dst[i][0];
      final v = dst[i][1];

      a.add([x, y, 1, 0, 0, 0, -u * x, -u * y]);
      a.add([0, 0, 0, x, y, 1, -v * x, -v * y]);
      b.add([u]);
      b.add([v]);
    }

    // Solve using Gaussian elimination
    final result = _solveLinearSystem(a, b);
    return [
      [result[0], result[1], result[2]],
      [result[3], result[4], result[5]],
      [result[6], result[7], 1.0],
    ];
  }

  List<double> _solveLinearSystem(List<List<double>> a, List<List<double>> b) {
    const n = 8;
    final augmented = List.generate(n, (i) => List<double>.from([...a[i], ...b[i]]));

    // Forward elimination
    for (int col = 0; col < n; col++) {
      // Find pivot
      int maxRow = col;
      for (int row = col + 1; row < n; row++) {
        if (augmented[row][col].abs() > augmented[maxRow][col].abs()) {
          maxRow = row;
        }
      }

      // Swap rows
      final temp = augmented[col];
      augmented[col] = augmented[maxRow];
      augmented[maxRow] = temp;

      // Eliminate column
      for (int row = col + 1; row < n; row++) {
        final factor = augmented[row][col] / augmented[col][col];
        for (int j = col; j <= n; j++) {
          augmented[row][j] -= factor * augmented[col][j];
        }
      }
    }

    // Back substitution
    final result = List<double>.filled(n, 0);
    for (int i = n - 1; i >= 0; i--) {
      result[i] = augmented[i][n];
      for (int j = i + 1; j < n; j++) {
        result[i] -= augmented[i][j] * result[j];
      }
      result[i] /= augmented[i][i];
    }

    return result;
  }

  List<double> _applyTransformMatrix(List<List<double>> matrix, double x, double y) {
    final w = matrix[2][0] * x + matrix[2][1] * y + matrix[2][2];
    return [
      (matrix[0][0] * x + matrix[0][1] * y + matrix[0][2]) / w,
      (matrix[1][0] * x + matrix[1][1] * y + matrix[1][2]) / w,
    ];
  }
}

class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  Point operator +(Point other) => Point(x + other.x, y + other.y);
  Point operator -(Point other) => Point(x - other.x, y - other.y);
  Point operator *(double factor) => Point(x * factor, y * factor);

  @override
  String toString() => 'Point($x, $y)';
}