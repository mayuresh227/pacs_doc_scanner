import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/scanner_provider.dart';
import '../../../preview/presentation/screens/preview_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/manual_crop_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureFromCamera() async {
    final cameraStatus = await Permission.camera.request();
    
    if (cameraStatus.isDenied) {
      _showPermissionDeniedDialog('Camera');
      return;
    }

    if (cameraStatus.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog('Camera');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: ${e.toString()}');
    }
  }

  Future<void> _uploadFromGallery() async {
    // Request storage permission for Android 10+
    final storageStatus = await Permission.photos.request();
    
    if (storageStatus.isDenied) {
      _showPermissionDeniedDialog('Storage');
      return;
    }

    if (storageStatus.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog('Storage');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 90,
      );

      if (images.isNotEmpty) {
        for (final image in images) {
          await _processImage(File(image.path));
        }
        _navigateToPreview();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to upload images: ${e.toString()}');
    }
  }

  Future<void> _processImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    // Always show manual crop UI for user to adjust corners
    _showManualCropScreen(imageFile, bytes);
  }

  void _showManualCropScreen(File imageFile, Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManualCropScreen(
          imageFile: imageFile,
          imageBytes: bytes,
        ),
      ),
    );
  }

  void _navigateToPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PreviewScreen(),
      ),
    );
  }

  void _showPermissionDeniedDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          'This feature requires $permission permission. Please grant the permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              requestPermission(permission);
            },
            child: const Text('Grant'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Denied'),
        content: Text(
          '$permission permission has been permanently denied. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> requestPermission(String permission) async {
    if (permission == 'Camera') {
      await Permission.camera.request();
    } else if (permission == 'Storage') {
      await Permission.photos.request();
    }
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

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PACS Document Scanner'),
      ),
      body: scannerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Scan Document',
                    subtitle: 'Capture document using camera',
                    onTap: _captureFromCamera,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  _buildActionCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Upload Document',
                    subtitle: 'Select images from gallery',
                    onTap: _uploadFromGallery,
                    color: AppTheme.secondaryColor,
                  ),
                  if (scannerState.error != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: AppTheme.errorColor.withAlpha(26),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                scannerState.error!,
                                style: const TextStyle(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                ref.read(scannerProvider.notifier).clearError();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}