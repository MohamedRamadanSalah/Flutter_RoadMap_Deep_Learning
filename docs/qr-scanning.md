# QR Code Scanning

## Overview

QR scanning uses `mobile_scanner` (v7.x) which leverages Google ML Kit on
Android and Apple Vision on iOS. It provides camera controls, a scan-window
region-of-interest, and multi-format barcode support.

## Setup

### Android

No additional setup required. `mobile_scanner` declares camera permissions
automatically via its own `AndroidManifest.xml`.

Minimum SDK: API 21 (project uses API 24 — compatible).

### iOS

Add camera usage description to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to scan QR codes</string>
```

## Basic Usage

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.scanner.title)),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;

    final value = barcode.rawValue;
    if (value == null) return;

    // Stop scanning after first result
    _controller.stop();

    // Process the scanned value
    _handleScanResult(value);
  }

  void _handleScanResult(String value) {
    // Navigate or process based on scanned content
    // Example: deep link, invitation code, ticket validation
    context.pop(value); // Return result to caller
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Scan Window (Region of Interest)

Restrict scanning to a specific area of the camera view:

```dart
MobileScanner(
  controller: _controller,
  scanWindow: Rect.fromCenter(
    center: MediaQuery.sizeOf(context).center(Offset.zero),
    width: 250,
    height: 250,
  ),
  onDetect: _onDetect,
)
```

Add a visual overlay to guide the user:

```dart
Stack(
  children: [
    MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
    ),
    // Overlay with cutout
    const ScannerOverlay(),
  ],
)
```

## Camera Controls

### Torch

```dart
IconButton(
  icon: Icon(
    _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
  ),
  onPressed: () => _controller.toggleTorch(),
)
```

### Switch Camera

```dart
IconButton(
  icon: const Icon(Icons.cameraswitch),
  onPressed: () => _controller.switchCamera(),
)
```

## Error Handling

```dart
MobileScanner(
  controller: _controller,
  onDetect: _onDetect,
  errorBuilder: (context, error, child) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, size: 48),
          Text(
            switch (error.errorCode) {
              MobileScannerErrorCode.permissionDenied =>
                t.scanner.permissionDenied,
              MobileScannerErrorCode.genericError =>
                t.scanner.cameraError,
              _ => t.errors.unknown,
            },
          ),
        ],
      ),
    );
  },
)
```

## Feature Integration Pattern

Place the scanner in the feature that uses it:

```
lib/features/invitations/
├── presentation/
│   ├── screens/
│   │   └── scan_invitation_screen.dart    # Uses MobileScanner
│   └── widgets/
│       └── scanner_overlay.dart           # Scan window overlay
```

If multiple features need scanning, extract the overlay widget to
`lib/shared/widgets/scanner_overlay.dart`.

## Supported Barcode Formats

`mobile_scanner` supports: QR Code, EAN-13, EAN-8, Code 128, Code 39,
Code 93, Codabar, ITF, UPC-A, UPC-E, PDF417, Aztec, DataMatrix.

To restrict formats:

```dart
MobileScannerController(
  formats: [BarcodeFormat.qrCode],
)
```

## Rules

- **DO** stop the scanner after detecting a valid result to prevent duplicate processing.
- **DO** dispose the `MobileScannerController` in `dispose()`.
- **DO** add the `NSCameraUsageDescription` to Info.plist.
- **DO** handle permission denied with a helpful error message.
- **DO** use a scan window overlay to guide the user.
- **DO NOT** process every detection event — debounce or stop after first valid result.
- **DO NOT** keep the camera running when navigating away from the scanner screen.
