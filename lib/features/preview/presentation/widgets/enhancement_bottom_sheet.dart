import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/image_enhancement_service.dart';
import '../../../scanner/presentation/providers/scanner_provider.dart';
import '../../../../core/theme/app_theme.dart';

class EnhancementBottomSheet extends ConsumerStatefulWidget {
  final File imageFile;
  final Uint8List imageBytes;
  final int pageIndex;

  const EnhancementBottomSheet({
    super.key,
    required this.imageFile,
    required this.imageBytes,
    required this.pageIndex,
  });

  @override
  ConsumerState<EnhancementBottomSheet> createState() => _EnhancementBottomSheetState();
}

class _EnhancementBottomSheetState extends ConsumerState<EnhancementBottomSheet> {
  EnhancementMode _currentMode = EnhancementMode.original;
  Uint8List? _processedBytes;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _processedBytes = widget.imageBytes;
  }

  Future<void> _applyEnhancement(EnhancementMode mode) async {
    if (_currentMode == mode) return;

    setState(() {
      _isProcessing = true;
      _currentMode = mode;
    });

    try {
      final service = ImageEnhancementService();
      final enhanced = await service.enhanceImage(
        imageBytes: widget.imageBytes,
        mode: mode,
      );

      if (enhanced != null && mounted) {
        setState(() {
          _processedBytes = enhanced;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _applyAndSave() async {
    if (_processedBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final enhancedFile = File('${tempDir.path}/enhanced_$timestamp.jpg');
      await enhancedFile.writeAsBytes(_processedBytes!);

      // Update the page in scanner state
      final scannerNotifier = ref.read(scannerProvider.notifier);
      final currentState = ref.read(scannerProvider);
      
      // Remove old page and add new one
      await scannerNotifier.removePage(widget.pageIndex);
      await scannerNotifier.addPage(enhancedFile);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply enhancement: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Image Enhancement',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_processedBytes != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _processedBytes!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModeButton(
                mode: EnhancementMode.original,
                icon: Icons.image,
                label: 'Original',
              ),
              _buildModeButton(
                mode: EnhancementMode.grayscale,
                icon: Icons.filter_b_and_w,
                label: 'Grayscale',
              ),
              _buildModeButton(
                mode: EnhancementMode.blackAndWhite,
                icon: Icons.contrast,
                label: 'B&W',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyAndSave,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required EnhancementMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentMode == mode;
    
    return InkWell(
      onTap: () => _applyEnhancement(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}