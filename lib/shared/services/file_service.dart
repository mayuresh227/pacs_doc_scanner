  import 'dart:io';
  import 'package:path_provider/path_provider.dart';

  class FileService {
    Future<Directory> getAppDocumentsDirectory() async {
      return await getApplicationDocumentsDirectory();
    }

  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

    Future<Directory> getExternalStorageDirectory() async {
      return await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }

  Future<String> getFilePath(String fileName) async {
    final directory = await getAppDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  Future<File> saveFile(String path, List<int> bytes) async {
    final file = File(path);
    return await file.writeAsBytes(bytes);
  }

  Future<File> copyFile(File source, String destinationPath) async {
    return await source.copy(destinationPath);
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  String getFileNameFromPath(String path) {
    return path.split('/').last;
  }

  String getFileExtension(String path) {
    final parts = path.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }
}