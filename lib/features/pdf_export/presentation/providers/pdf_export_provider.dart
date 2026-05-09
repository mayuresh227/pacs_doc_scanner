import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../../../scanner/presentation/providers/scanner_provider.dart';

class PdfExportState {
  final bool isGenerating;
  final String? pdfPath;
  final String? error;
  final double progress;
  final int pageCount;
  final int pdfSizeKB;
  final String? warning;
  final bool isOversized;

  PdfExportState({
    this.isGenerating = false,
    this.pdfPath,
    this.error,
    this.progress = 0.0,
    this.pageCount = 0,
    this.pdfSizeKB = 0,
    this.warning,
    this.isOversized = false,
  });

  PdfExportState copyWith({
    bool? isGenerating,
    String? pdfPath,
    String? error,
    double? progress,
    int? pageCount,
    int? pdfSizeKB,
    String? warning,
    bool? isOversized,
  }) {
    return PdfExportState(
      isGenerating: isGenerating ?? this.isGenerating,
      pdfPath: pdfPath,
      error: error,
      progress: progress ?? this.progress,
      pageCount: pageCount ?? this.pageCount,
      pdfSizeKB: pdfSizeKB ?? this.pdfSizeKB,
      warning: warning,
      isOversized: isOversized ?? this.isOversized,
    );
  }
}

class PdfExportNotifier extends StateNotifier<PdfExportState> {
  final Ref _ref;
  
  static const int maxSizeKB = 253;
  static const int maxAttempts = 3;
  static const int initialQuality = 90;
  static const int minQuality = 30;
  static const int qualityStep = 20;

  PdfExportNotifier(this._ref) : super(PdfExportState());

  String _generateFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'KYC_$timestamp.pdf';
  }

  Future<void> generatePdf() async {
    final scannerState = _ref.read(scannerProvider);
    
    if (scannerState.pages.isEmpty) {
      state = state.copyWith(error: 'No pages to export');
      return;
    }

    state = PdfExportState(
      isGenerating: true,
      progress: 0.0,
      pageCount: scannerState.pages.length,
    );

    try {
      String? finalPath;
      int currentQuality = initialQuality;
      int attempts = 0;
      bool sizeValidated = false;

      while (attempts < maxAttempts && !sizeValidated) {
        attempts++;
        
        state = state.copyWith(
          progress: 0.0,
          warning: attempts > 1 ? 'Attempt $attempts: Reducing quality to $currentQuality%...' : null,
        );

        final pdfPath = await _buildPdf(scannerState, currentQuality);
        
        if (pdfPath == null) {
          state = state.copyWith(
            isGenerating: false,
            error: 'Failed to generate PDF',
          );
          return;
        }

        final file = File(pdfPath);
        final sizeBytes = await file.length();
        final sizeKB = sizeBytes ~/ 1024;

        if (sizeKB <= maxSizeKB) {
          sizeValidated = true;
          finalPath = pdfPath;
          state = state.copyWith(
            isGenerating: false,
            pdfPath: finalPath,
            pdfSizeKB: sizeKB,
            progress: 1.0,
          );
        } else {
          currentQuality -= qualityStep;
          
          if (currentQuality < minQuality) {
            finalPath = pdfPath;
            state = state.copyWith(
              isGenerating: false,
              pdfPath: finalPath,
              pdfSizeKB: sizeKB,
              isOversized: true,
              warning: 'PDF size (${sizeKB}KB) exceeds recommended limit. Consider reducing number of pages.',
              progress: 1.0,
            );
            sizeValidated = true;
          } else {
            await file.delete();
          }
        }
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate PDF: ${e.toString()}',
      );
    }
  }

  Future<String?> _buildPdf(dynamic scannerState, int quality) async {
    final pdf = pw.Document();
    final pages = scannerState.pages as List;
    final totalPages = pages.length;

    const pageFormat = PdfPageFormat.a4;
    const margin = 36.0;
    const contentWidth = pageFormat.width - (margin * 2);
    const contentHeight = pageFormat.height - (margin * 2);

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final file = File(page.filePath as String);
      
      if (!await file.exists()) {
        continue;
      }

      // Read and potentially re-compress image with specified quality
      final bytes = await file.readAsBytes();
      final compressedBytes = await _compressImageWithQuality(bytes, quality);
      final image = pw.MemoryImage(compressedBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
                width: contentWidth,
                height: contentHeight,
              ),
            );
          },
        ),
      );

      state = state.copyWith(
        progress: (i + 1) / totalPages * 0.9,
      );
    }

    final fileName = _generateFileName();
    final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    final Uint8List pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

    return filePath;
  }

  Future<Uint8List> _compressImageWithQuality(Uint8List bytes, int quality) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;
      
      // Re-encode with specified quality
      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (e) {
      // If compression fails, return original bytes
      return bytes;
    }
  }

  Future<void> sharePdf() async {
    if (state.pdfPath == null) {
      state = state.copyWith(error: 'No PDF to share');
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(state.pdfPath!)],
        text: 'KYC Document',
        subject: 'KYC Document',
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to share PDF: ${e.toString()}');
    }
  }

  Future<String?> savePdfToStorage() async {
    if (state.pdfPath == null) {
      state = state.copyWith(error: 'No PDF to save');
      return null;
    }

    try {
      final fileName = _generateFileName();
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/$fileName';

      final sourceFile = File(state.pdfPath!);
      await sourceFile.copy(newPath);

      state = state.copyWith(pdfPath: newPath);
      return newPath;
    } catch (e) {
      state = state.copyWith(error: 'Failed to save PDF: ${e.toString()}');
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearWarning() {
    state = state.copyWith(warning: null);
  }

  void reset() {
    state = PdfExportState();
  }
}

final pdfExportProvider = StateNotifierProvider<PdfExportNotifier, PdfExportState>((ref) {
  return PdfExportNotifier(ref);
});