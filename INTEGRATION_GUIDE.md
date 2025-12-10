# iOS MFI Integration Guide for TSC Printers

## 📋 Quick Summary

This repo adds **iOS MFI (Made for iPhone)** support to `bluetooth_print_plus` for TSC printers like TSC TDM-30.

- ✅ Android: Uses BLE (existing functionality)
- ✅ iOS: Uses MFI via ExternalAccessory framework

## 🚀 How to Integrate into Your App

### 1️⃣ Add to `pubspec.yaml`

Replace the original `bluetooth_print_plus` dependency with this repo:

```yaml
dependencies:
  bluetooth_print_plus:
    git:
      url: https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
      ref: main # or specific branch/tag
```

### 2️⃣ Configure iOS Project

Add to `ios/Runner/Info.plist`:

```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.issc.datapath</string>
</array>
```

### 3️⃣ Update Your Helper Class

Copy the code pattern from `example/lib/tsc_printer_utils_updated.dart` to your `TSCPrinterUtils` class.

Key changes:
```dart
import 'dart:io';

class TSCPrinterUtils {
  /// Check if running on iOS
  bool get isIOS => Platform.isIOS;

  /// [iOS ONLY] List connected MFI accessories
  Future<List<Map<String, dynamic>>> listMfiAccessories() async {
    if (!isIOS) return [];
    return await TscMfiChannel.listAccessories();
  }

  /// [iOS ONLY] Check if MFI printer is available
  Future<bool> isMfiPrinterAvailable() async {
    if (!isIOS) return false;
    final accessories = await listMfiAccessories();
    return accessories.isNotEmpty;
  }

  /// Print barcode labels - works on both Android and iOS
  Future<bool> printBarcodeLabels({
    required String patientName,
    required List<LisBarcodeData> barcodes,
  }) async {
    // Build TSC commands (same as before)
    final StringBuffer tscCommand = StringBuffer();
    tscCommand.write('SIZE 72 mm, 25 mm\r\n');
    // ... rest of your commands

    // Platform-specific print
    if (isIOS) {
      // iOS MFI: Use executePrintJob (one native call)
      await TscMfiChannel.executePrintJob(tscCommand.toString());
    } else {
      // Android BLE: Use BluetoothPrintPlus.write (existing code)
      final commandBytes = Uint8List.fromList(utf8.encode(tscCommand.toString()));
      await BluetoothPrintPlus.write(commandBytes);
    }

    return true;
  }
}
```

### 4️⃣ Update Your UI Logic

```dart
// In your print screen/widget
if (Platform.isIOS) {
  // iOS: Check MFI accessories
  final printerUtils = TSCPrinterUtils();
  final accessories = await printerUtils.listMfiAccessories();

  if (accessories.isEmpty) {
    // Show message: "Please pair printer in Settings > Bluetooth"
    return;
  }

  // Enable print button
  print('Found MFI printer: ${accessories.first['name']}');
} else {
  // Android: Use existing BLE scan logic
  // Your existing code...
}

// Print (works on both platforms)
await TSCPrinterUtils().printBarcodeLabels(
  patientName: patientName,
  barcodes: barcodes,
);
```

## ⚠️ Important Notes

### iOS MFI Workflow
1. User pairs TSC printer in **iOS Settings > Bluetooth** (OUTSIDE your app)
2. User returns to your app
3. App calls `TscMfiChannel.listAccessories()` to check paired devices
4. If found, enable print button
5. Print directly without connecting - iOS manages the connection

### Android BLE Workflow (unchanged)
1. App scans for devices via `BluetoothPrintPlus.startScan()`
2. User selects printer from list
3. App connects via `BluetoothPrintPlus.connect()`
4. Print via `BluetoothPrintPlus.write()`

## 📦 Before Pushing to GitHub

1. **Clean up** (already done):
   - ✅ Removed `swift_sample/` folder
   - ✅ Removed debug files: `iOS_Swift.pdf`, `INTEGRATION_SUMMARY.md`, etc.

2. **Commit all changes**:
   ```bash
   git add .
   git commit -m "feat: Add iOS MFI support for TSC printers

   - Add TscMfiPlugin.swift with tscswift framework integration
   - Add TscMfiChannel.dart for Flutter API
   - Add executePrintJob() method for optimal performance
   - Update example app with MFI demo
   - Update README with iOS MFI usage guide

   Supports TSC TDM-30 and other MFI-enabled TSC printers"
   ```

3. **Create new GitHub repo** and push:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   git branch -M main
   git push -u origin main
   ```

4. **Add to your app's pubspec.yaml**:
   ```yaml
   bluetooth_print_plus:
     git:
       url: https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
       ref: main
   ```

## 🧪 Testing

### iOS Testing
1. Pair TSC printer in iOS Settings > Bluetooth
2. Launch app
3. Check if `listMfiAccessories()` returns the printer
4. Tap print button - should print immediately

### Android Testing (unchanged)
1. Scan for devices
2. Connect to printer
3. Print - should work as before

## 📚 API Reference

### iOS MFI Methods

```dart
// List all paired MFI accessories
Future<List<Map<String, dynamic>>> TscMfiChannel.listAccessories()

// Execute complete print job (recommended - best performance)
Future<void> TscMfiChannel.executePrintJob(String commands)

// Alternative methods (for advanced use)
Future<bool> TscMfiChannel.openPortMfi()
Future<void> TscMfiChannel.sendCommand(String command)
Future<void> TscMfiChannel.closePort()
Future<void> TscMfiChannel.clearBuffer()
```

### Recommended Pattern

**Use `executePrintJob()`** for best performance:
- ✅ One method channel call (vs 10+ calls)
- ✅ No UI blocking
- ✅ Matches native Swift performance
- ✅ Complete workflow in native code

```dart
// Build commands
final buffer = StringBuffer();
buffer.write('SIZE 72 mm, 25 mm\r\n');
buffer.write('GAP 0 mm, 0 mm\r\n');
buffer.write('CLS\r\n');
buffer.write('TEXT 30,30,"2",0,2,2,"Test"\r\n');

// Execute in one call
await TscMfiChannel.executePrintJob(buffer.toString());
```

## ✅ Complete Checklist

- [ ] Add repo to `pubspec.yaml` with git URL
- [ ] Update `Info.plist` with `com.issc.datapath` protocol
- [ ] Copy iOS MFI methods to your `TSCPrinterUtils` class
- [ ] Add platform check (`Platform.isIOS`) in your UI
- [ ] Use `listMfiAccessories()` for iOS instead of BLE scan
- [ ] Test on real iOS device with TSC TDM-30 printer
- [ ] Test Android still works with existing BLE flow

---

Need help? Check the example app in `example/lib/main.dart` for complete implementation.
