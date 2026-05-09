import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../scanner/domain/entities/scanned_document.dart';
import '../../../scanner/presentation/providers/scanner_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pdf_export/presentation/screens/pdf_export_screen.dart';
import '../widgets/enhancement_bottom_sheet.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _scanMore() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 90,
      );

      if (images.isNotEmpty) {
        for (final image in images) {
          await ref.read(scannerProvider.notifier).addPage(File(image.path));
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add pages: ${e.toString()}');
    }
  }

  void _deletePage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: const Text('Are you sure you want to delete this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(scannerProvider.notifier).removePage(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEnhancementSheet(int pageIndex, ScannedPage page) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancementBottomSheet(
        imageFile: File(page.filePath),
        imageBytes: page.bytes ?? File(page.filePath).readAsBytesSync().buffer.asUint8List(),
        pageIndex: pageIndex,
      ),
    );
  }

  void _navigateToPdfExport() {
    final state = ref.read(scannerProvider);
    if (state.pages.isEmpty) {
      _showErrorSnackBar('No pages to export');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PdfExportScreen(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _estimatePdfSize(int pageCount) {
    // Rough estimate: ~50KB per page after compression
    final estimatedKB = pageCount * 50;
    if (estimatedKB < 1024) {
      return '~$estimatedKB KB';
    } else {
      return '~${(estimatedKB / 1024).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${scannerState.pages.length} Pages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _scanMore,
            tooltip: 'Scan more',
          ),
        ],
      ),
      body: scannerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : scannerState.pages.isEmpty
              ? _buildEmptyState()
              : _buildContent(scannerState),
      bottomNavigationBar: scannerState.pages.isNotEmpty
          ? _buildBottomBar(scannerState)
          : null,
      floatingActionButton: scannerState.pages.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _navigateToPdfExport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export PDF'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No pages scanned yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _scanMore,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Scan More'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ScannerState state) {
    return Column(
      children: [
        _buildSizeEstimate(state),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.pages.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              ref.read(scannerProvider.notifier).reorderPages(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final page = state.pages[index];
              return _buildPageCard(page, index, state.pages.length);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSizeEstimate(ScannerState state) {
    final estimate = _estimatePdfSize(state.pages.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'Estimated PDF size: $estimate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageCard(ScannedPage page, int index, int total) {
    return Card(
      key: ValueKey(page.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEnhancementSheet(index, page),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(page.filePath),
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // Page info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to enhance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.errorColor,
                ),
                onPressed: () => _deletePage(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(ScannerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.add_a_photo,
              label: 'Scan More',
              onTap: _scanMore,
            ),
            _buildActionButton(
              icon: Icons.reorder,
              label: 'Drag to Reorder',
              onTap: null,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled ? AppTheme.primaryColor : Colors.grey[400],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled ? AppTheme.primaryColor : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}