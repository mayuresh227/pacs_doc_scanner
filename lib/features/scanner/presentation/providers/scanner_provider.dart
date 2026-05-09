  import 'dart:io';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../domain/entities/scanned_document.dart';
  import '../../../../shared/services/adaptive_compression_service.dart';
  import '../../../../shared/services/file_service.dart';
  import '../../../../shared/services/image_processing_service.dart';

class ScannerState {
  final List<ScannedPage> pages;
  final bool isLoading;
  final String? error;
  final int currentIndex;

  ScannerState({
    this.pages = const [],
    this.isLoading = false,
    this.error,
    this.currentIndex = 0,
  });

  ScannerState copyWith({
    List<ScannedPage>? pages,
    bool? isLoading,
    String? error,
    int? currentIndex,
  }) {
    return ScannerState(
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  final AdaptiveCompressionService _compressionService;
  final FileService _fileService;
  final ImageProcessingService _imageProcessingService;

  ScannerNotifier(this._compressionService, this._fileService, this._imageProcessingService)
      : super(ScannerState());

  Future<void> addPage(File imageFile, {bool applyGrayscale = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use adaptive compression with grayscale
      final compressedFile = await _compressionService.compressAdaptive(
        imageFile,
        applyGrayscale: applyGrayscale,
      );
      
      final fileToUse = compressedFile ?? imageFile;

      final page = ScannedPage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: fileToUse.path,
        scannedAt: DateTime.now(),
      );

      state = state.copyWith(
        pages: [...state.pages, page],
        isLoading: false,
        currentIndex: state.pages.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add page: ${e.toString()}',
      );
    }
  }

  Future<void> addPageWithGrayscale(File imageFile) async {
    await addPage(imageFile, applyGrayscale: true);
  }

  Future<void> removePage(int index) async {
    if (index < 0 || index >= state.pages.length) return;

    final updatedPages = List<ScannedPage>.from(state.pages);
    updatedPages.removeAt(index);

    int newIndex = state.currentIndex;
    if (index <= state.currentIndex && state.currentIndex > 0) {
      newIndex = state.currentIndex - 1;
    }
    if (newIndex >= updatedPages.length) {
      newIndex = updatedPages.isEmpty ? 0 : updatedPages.length - 1;
    }

    state = state.copyWith(
      pages: updatedPages,
      currentIndex: newIndex,
    );
  }

  Future<void> rotatePage(int index, int degrees) async {
    if (index < 0 || index >= state.pages.length) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = state.pages[index];
      final file = File(page.filePath);
      
      // Actually rotate the image using ImageProcessingService
      final rotatedFile = await _imageProcessingService.rotateImage(file, degrees);

      if (rotatedFile != null) {
        final updatedPages = List<ScannedPage>.from(state.pages);
        updatedPages[index] = page.copyWith(
          filePath: rotatedFile.path,
          rotation: (page.rotation + degrees) % 360,
        );

        state = state.copyWith(
          pages: updatedPages,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to rotate image',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to rotate page: ${e.toString()}',
      );
    }
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.pages.length) return;
    if (newIndex < 0 || newIndex >= state.pages.length) return;

    final updatedPages = List<ScannedPage>.from(state.pages);
    final page = updatedPages.removeAt(oldIndex);
    updatedPages.insert(newIndex, page);

    int currentIndex = state.currentIndex;
    if (oldIndex == state.currentIndex) {
      currentIndex = newIndex;
    } else if (oldIndex < state.currentIndex && newIndex >= state.currentIndex) {
      currentIndex--;
    } else if (oldIndex > state.currentIndex && newIndex <= state.currentIndex) {
      currentIndex++;
    }

    state = state.copyWith(
      pages: updatedPages,
      currentIndex: currentIndex,
    );
  }

  void setCurrentIndex(int index) {
    if (index < 0 || index >= state.pages.length) return;
    state = state.copyWith(currentIndex: index);
  }

  void clearDocument() {
    state = ScannerState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final adaptiveCompressionServiceProvider = Provider<AdaptiveCompressionService>((ref) {
  return AdaptiveCompressionService();
});

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return ImageProcessingService();
});

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final compressionService = ref.watch(adaptiveCompressionServiceProvider);
  final fileService = ref.watch(fileServiceProvider);
  final imageProcessingService = ref.watch(imageProcessingServiceProvider);
  return ScannerNotifier(compressionService, fileService, imageProcessingService);
});
