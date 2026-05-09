import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  Future<bool> checkStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  Future<bool> isCameraPermissionDenied() async {
    return await Permission.camera.isDenied;
  }

  Future<bool> isCameraPermissionPermanentlyDenied() async {
    return await Permission.camera.isPermanentlyDenied;
  }

  Future<void> openAppSettings() async {
    await Permission.camera.openAppSettings();
  }
}