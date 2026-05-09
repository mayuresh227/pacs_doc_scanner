/// Stub document detection service that provides default rectangle corners.
/// No ML Kit or native dependencies - pure Dart implementation.
class DocumentDetectionResult {
  final List<Offset> corners;
  final double confidence;
  final bool detected;

  DocumentDetectionResult({
    required this.corners,
    required this.confidence,
    required this.detected,
  });
}

class DocumentDetectionService {
  /// Returns default corners covering the full image area (0.05 to 0.95).
  /// This allows manual adjustment without requiring ML-based detection.
  Future<DocumentDetectionResult?> detectDocument(String imagePath) async {
    return DocumentDetectionResult(
      corners: [
        const Offset(0.05, 0.05),
        const Offset(0.95, 0.05),
        const Offset(0.95, 0.95),
        const Offset(0.05, 0.95),
      ],
      confidence: 0.0,
      detected: false,
    );
  }

  Future<DocumentDetectionResult?> detectDocumentFromBytes(List<int> bytes) async {
    return DocumentDetectionResult(
      corners: [
        const Offset(0.05, 0.05),
        const Offset(0.95, 0.05),
        const Offset(0.95, 0.95),
        const Offset(0.05, 0.95),
      ],
      confidence: 0.0,
      detected: false,
    );
  }

  void dispose() {
    // No-op - no native resources to dispose
  }
}

class Offset {
  final double dx;
  final double dy;

  const Offset(this.dx, this.dy);

  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);
  Offset operator -(Offset other) => Offset(dx - other.dx, dy - other.dy);
  Offset operator *(double factor) => Offset(dx * factor, dy * factor);

  @override
  String toString() => 'Offset($dx, $dy)';
}