import 'dart:typed_data';
import 'package:flutter/services.dart';

/// TSC MFI (Made for iPhone) Bluetooth Channel
/// This channel provides access to TSC printer MFI bluetooth connection on iOS
///
/// On iOS, TSC printers require MFI (ExternalAccessory) bluetooth connection
/// instead of standard BLE connection. This is different from Android.
class TscMfiChannel {
  static const MethodChannel _channel =
      MethodChannel('bluetooth_print_plus_tsc_mfi');

  /// Open MFI bluetooth connection to TSC printer
  ///
  /// This will automatically discover and connect to the first available
  /// TSC printer accessory via ExternalAccessory framework.
  ///
  /// Returns true if connection successful, throws PlatformException on error
  ///
  /// Note: Your app's Info.plist must include:
  /// - UISupportedExternalAccessoryProtocols with value: com.tscprinters.escpos
  static Future<bool> openPortMfi() async {
    try {
      final result = await _channel.invokeMethod<bool>('openport_mfi');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to open MFI port: ${e.message}');
    }
  }

  /// Close MFI bluetooth connection
  ///
  /// [delay] - Optional delay in seconds before closing (default: 0)
  ///
  /// Returns true if successfully closed
  static Future<bool> closePort({double delay = 0}) async {
    try {
      final result = await _channel.invokeMethod<bool>('closeport', {
        'delay': delay,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to close port: ${e.message}');
    }
  }

  /// Send TSC command string to printer
  ///
  /// [command] - TSC command string (e.g., "SIZE 72 mm, 25 mm\r\n")
  /// [delay] - Optional delay in seconds after sending (default: 0)
  ///
  /// Returns true if command sent successfully
  static Future<bool> sendCommand(String command, {double delay = 0}) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendcommand', {
        'command': command,
        'delay': delay,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to send command: ${e.message}');
    }
  }

  /// Send UTF-8 encoded TSC command string to printer
  ///
  /// Use this for commands containing UTF-8 text
  ///
  /// [command] - TSC command string with UTF-8 text
  /// [delay] - Optional delay in seconds after sending (default: 0)
  ///
  /// Returns true if command sent successfully
  static Future<bool> sendCommandUtf8(String command, {double delay = 0}) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendcommand_utf8', {
        'command': command,
        'delay': delay,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to send UTF-8 command: ${e.message}');
    }
  }

  /// Send binary data to printer
  ///
  /// [data] - Binary data to send (e.g., image data, raw commands)
  /// [delay] - Optional delay in seconds after sending (default: 0)
  ///
  /// Returns true if data sent successfully
  static Future<bool> sendCommandWithData(
    Uint8List data, {
    double delay = 0,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendCommandWithData', {
        'data': data,
        'delay': delay,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to send command data: ${e.message}');
    }
  }

  /// Get printer status
  ///
  /// [delay] - Optional delay in seconds before reading status (default: 2.0)
  ///
  /// Returns status string from printer
  /// Common status values:
  /// - "00": Normal
  /// - "01": Head opened
  /// - "10": Pause
  static Future<String> printerStatus({double delay = 2.0}) async {
    try {
      final result = await _channel.invokeMethod<String>('printer_status', {
        'delay': delay,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to get printer status: ${e.message}');
    }
  }

  /// Check if currently connected to TSC printer via MFI
  ///
  /// Returns true if connected
  static Future<bool> isConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to check connection status: ${e.message}');
    }
  }

  /// List all connected External Accessories (for debugging)
  ///
  /// Returns list of accessory information including:
  /// - name: Device name
  /// - manufacturer: Manufacturer name
  /// - model: Model number
  /// - serial: Serial number
  /// - protocols: Supported protocol strings
  ///
  /// Use this to debug MFI connection issues
  static Future<List<Map<String, dynamic>>> listAccessories() async {
    try {
      final result = await _channel.invokeMethod<List>('listAccessories');
      if (result == null) return [];

      return result
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to list accessories: ${e.message}');
    }
  }

  /// Clear printer buffer
  ///
  /// Clears any pending commands in the printer's buffer
  /// Call this before sending new print commands to ensure clean state
  static Future<bool> clearBuffer() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearBuffer');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to clear buffer: ${e.message}');
    }
  }

  /// Print labels using native printlabel method
  ///
  /// [sets] - Number of label sets to print
  /// [copies] - Number of copies of each set
  ///
  /// This uses the tscswift framework's printlabel() method
  /// which properly handles the print job execution
  static Future<bool> printLabel({required int sets, required int copies}) async {
    try {
      final result = await _channel.invokeMethod<bool>('printLabel', {
        'sets': sets,
        'copies': copies,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to print label: ${e.message}');
    }
  }

  /// Send multiple TSC commands at once (batch)
  ///
  /// This is more efficient and reliable than sending commands one by one
  /// Similar to how Android BluetoothPrintPlus.write() works
  ///
  /// [commands] - String buffer containing all TSC commands
  ///
  /// Example:
  /// ```dart
  /// final buffer = StringBuffer();
  /// buffer.write('SIZE 72 mm, 25 mm\r\n');
  /// buffer.write('GAP 0 mm, 0 mm\r\n');
  /// buffer.write('CLS\r\n');
  /// buffer.write('TEXT 30,30,"2",0,2,2,"Test"\r\n');
  /// buffer.write('PRINT 1\r\n');
  /// await TscMfiChannel.sendCommandBatch(buffer.toString());
  /// ```
  static Future<bool> sendCommandBatch(String commands) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendcommand', {
        'command': commands,
        'delay': 0.0,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to send command batch: ${e.message}');
    }
  }

  /// Execute complete print job (open → commands → print → close)
  ///
  /// **BEST METHOD** - Does everything in ONE native call, exactly like swift_sample
  /// This avoids multiple method channel calls which can block UI
  ///
  /// [commands] - All TSC commands (SIZE, GAP, TEXT, etc.) in one string
  ///
  /// Example:
  /// ```dart
  /// final buffer = StringBuffer();
  /// buffer.write('DIRECTION 1\r\n');
  /// buffer.write('SIZE 72 mm, 25 mm\r\n');
  /// buffer.write('GAP 0 mm, 0 mm\r\n');
  /// buffer.write('CLS\r\n');
  /// buffer.write('TEXT 30,30,"2",0,2,2,"Test"\r\n');
  /// await TscMfiChannel.executePrintJob(buffer.toString());
  /// ```
  ///
  /// This method automatically:
  /// - Opens MFI port
  /// - Sends all commands
  /// - Prints label
  /// - Closes port
  static Future<bool> executePrintJob(String commands) async {
    try {
      final result = await _channel.invokeMethod<bool>('executePrintJob', {
        'commands': commands,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to execute print job: ${e.message}');
    }
  }
}
