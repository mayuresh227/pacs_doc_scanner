# PACS Document Scanner

A Flutter application for scanning, previewing, editing, and exporting documents as PDF. Built for Primary Agricultural Credit Societies (PACs) to digitize physical documents.

## Features

- **Document Scanning**: Capture documents using device camera
- **Image Upload**: Select multiple images from gallery
- **Preview & Edit**: View, rotate, crop, and reorder scanned pages
- **PDF Export**: Generate multi-page PDF documents
- **Share & Save**: Share PDF via system share sheet or save to device

## Architecture

Clean Architecture with feature-based folder structure:

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── widgets/
├── features/
│   ├── scanner/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── preview/
│   │   └── presentation/
│   └── pdf_export/
│       └── presentation/
└── shared/
    └── services/
```

## Dependencies

- `flutter_riverpod` - State management
- `image_picker` - Camera/gallery image capture
- `google_mlkit_object_detection` - Document detection
- `flutter_image_compress` - Image compression
- `image` - Image processing
- `pdf` - PDF generation
- `path_provider` - File system paths
- `share_plus` - Share functionality
- `permission_handler` - Permission handling

## Setup

1. Install Flutter SDK (3.x)
2. Run `flutter pub get`
3. Run `flutter run`

## Android Configuration

Required permissions:
- `android.permission.CAMERA`
- `android.permission.READ_EXTERNAL_STORAGE`
- `android.permission.WRITE_EXTERNAL_STORAGE`
- `android.permission.READ_MEDIA_IMAGES`

## License

Proprietary - PACS