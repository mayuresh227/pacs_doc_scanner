import 'dart:typed_data';

class ScannedPage {
  final String id;
  final String filePath;
  final Uint8List? bytes;
  final DateTime scannedAt;
  final int rotation;

  ScannedPage({
    required this.id,
    required this.filePath,
    this.bytes,
    required this.scannedAt,
    this.rotation = 0,
  });

  ScannedPage copyWith({
    String? id,
    String? filePath,
    Uint8List? bytes,
    DateTime? scannedAt,
    int? rotation,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      bytes: bytes ?? this.bytes,
      scannedAt: scannedAt ?? this.scannedAt,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScannedPage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ScannedDocument {
  final String id;
  final List<ScannedPage> pages;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  ScannedDocument({
    required this.id,
    required this.pages,
    required this.createdAt,
    this.modifiedAt,
  });

  ScannedDocument copyWith({
    String? id,
    List<ScannedPage>? pages,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  int get pageCount => pages.length;
  bool get isEmpty => pages.isEmpty;
  bool get isNotEmpty => pages.isNotEmpty;
}