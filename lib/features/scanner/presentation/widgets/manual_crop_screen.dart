import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/perspective_transform_service.dart';
import '../providers/scanner_provider.dart';
import '../../../../core/theme/app_theme.dart';

class ManualCropScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final Uint8List imageBytes;
  final List<Offset>? detectedCorners;

  const ManualCropScreen({
    super.key,
    required this.imageFile,
    required this.imageBytes,
    this.detectedCorners,
  });

  @override
  ConsumerState<ManualCropScreen> createState() => _ManualCropScreenState();
}

class _ManualCropScreenState extends ConsumerState<ManualCropScreen> {
  late List<Offset> _corners;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _corners = widget.detectedCorners ?? [
      const Offset(0.1, 0.1),
      const Offset(0.9, 0.1),
      const Offset(0.9, 0.9),
      const Offset(0.1, 0.9),
    ];
  }

  void _updateCorner(int index, Offset newPosition) {
    setState(() {
      _corners[index] = newPosition;
    });
  }

  Future<void> _applyCrop() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final transformService = PerspectiveTransformService();
      
      final imageSize = await _getImageSize();
      final absoluteCorners = _corners.map((corner) {
        return Point(corner.dx * imageSize.width, corner.dy * imageSize.height);
      }).toList();

      final croppedBytes = await transformService.applyPerspectiveTransform(
        imageBytes: widget.imageBytes,
        corners: absoluteCorners,
      );

      if (croppedBytes != null) {
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final croppedFile = File('${tempDir.path}/cropped_$timestamp.jpg');
        await croppedFile.writeAsBytes(croppedBytes);

        await ref.read(scannerProvider.notifier).addPage(croppedFile);
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showError('Failed to crop image');
      }
    } catch (e) {
      _showError('Crop failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<Size> _getImageSize() async {
    final image = await decodeImageFromList(widget.imageBytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Corners'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _applyCrop,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Done',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : _buildCropUI(),
    );
  }

  Widget _buildCropUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Image
            Center(
              child: Image.memory(
                widget.imageBytes,
                fit: BoxFit.contain,
              ),
            ),
            // Corner handles
            ...List.generate(4, (index) {
              return Positioned(
                left: _corners[index].dx * constraints.maxWidth - 20,
                top: _corners[index].dy * constraints.maxHeight - 20,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final newX = (_corners[index].dx + details.delta.dx / constraints.maxWidth).clamp(0.0, 1.0);
                    final newY = (_corners[index].dy + details.delta.dy / constraints.maxHeight).clamp(0.0, 1.0);
                    _updateCorner(index, Offset(newX, newY));
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.drag_indicator,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),
            // Connecting lines
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: CornerLinesPainter(_corners),
            ),
            // Instructions
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(179),
                        borderRadius: BorderRadius.circular(12),
                      ),
                child: const Text(
                  'Drag the corners to adjust the document boundaries',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CornerLinesPainter extends CustomPainter {
  final List<Offset> corners;

  CornerLinesPainter(this.corners);

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final scaledCorners = corners.map((c) => Offset(c.dx * size.width, c.dy * size.height)).toList();

    path.moveTo(scaledCorners[0].dx, scaledCorners[0].dy);
    for (int i = 1; i < scaledCorners.length; i++) {
      path.lineTo(scaledCorners[i].dx, scaledCorners[i].dy);
    }
    path.close();

    // Fill with semi-transparent
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.primaryColor.withAlpha(51)
        ..style = PaintingStyle.fill,
    );

    // Draw border
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}