import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pdf_export_provider.dart';
import '../../../../core/theme/app_theme.dart';

class PdfExportScreen extends ConsumerStatefulWidget {
  const PdfExportScreen({super.key});

  @override
  ConsumerState<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends ConsumerState<PdfExportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfExportProvider.notifier).generatePdf();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(pdfExportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export PDF'),
      ),
      body: _buildBody(pdfState),
    );
  }

  Widget _buildBody(PdfExportState state) {
    if (state.isGenerating) {
      return _buildGeneratingView(state);
    }

    if (state.error != null) {
      return _buildErrorView(state);
    }

    if (state.pdfPath != null) {
      return _buildSuccessView(state);
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildGeneratingView(PdfExportState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Generating PDF...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Text(
              '${(state.progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (state.warning != null) ...[
              const SizedBox(height: 16),
              Text(
                state.warning!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(PdfExportState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(pdfExportProvider.notifier).clearError();
                ref.read(pdfExportProvider.notifier).generatePdf();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(PdfExportState state) {
    final fileName = 'KYC_${DateTime.now().millisecondsSinceEpoch}.pdf';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isOversized && state.warning != null) ...[
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Large File Size',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.warning!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange[700],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    state.isOversized ? Icons.warning : Icons.check_circle,
                    size: 80,
                    color: state.isOversized ? Colors.orange : AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.isOversized ? 'PDF Generated (Oversized)' : 'PDF Generated Successfully!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: state.isOversized ? Colors.orange[700] : AppTheme.secondaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.pageCount} pages • ${state.pdfSizeKB}KB',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPreviewCard(state, fileName),
          const SizedBox(height: 24),
          _buildActionButtons(state),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(PdfExportState state, String fileName) {
    return Card(
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.picture_as_pdf,
                size: 80,
                color: state.isOversized ? Colors.orange : AppTheme.primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${state.pdfSizeKB} KB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: state.isOversized ? Colors.orange[700] : Colors.grey[600],
                          ),
                    ),
                    if (state.isOversized) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Exceeds 253KB',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PdfExportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            ref.read(pdfExportProvider.notifier).sharePdf();
          },
          icon: const Icon(Icons.share),
          label: const Text('Share PDF'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final savedPath = await ref.read(pdfExportProvider.notifier).savePdfToStorage();
            if (savedPath != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved: $savedPath'),
                  backgroundColor: AppTheme.secondaryColor,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          icon: const Icon(Icons.save_alt),
          label: const Text('Save to Device'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}