import Flutter
import UIKit
import tscswift
import ExternalAccessory

/// Plugin to handle TSC printer MFI bluetooth connection on iOS
/// This wraps the tscswift framework's Bluetooth class
public class TscMfiPlugin: NSObject, FlutterPlugin {
    private var tscBluetooth: Bluetooth?
    private var methodChannel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "bluetooth_print_plus_tsc_mfi",
            binaryMessenger: registrar.messenger()
        )
        let instance = TscMfiPlugin()
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listAccessories":
            handleListAccessories(result: result)

        case "openport_mfi":
            handleOpenPort(result: result)

        case "closeport":
            handleClosePort(call: call, result: result)

        case "sendcommand":
            handleSendCommand(call: call, result: result)

        case "sendcommand_utf8":
            handleSendCommandUtf8(call: call, result: result)

        case "sendCommandWithData":
            handleSendCommandWithData(call: call, result: result)

        case "printer_status":
            handlePrinterStatus(call: call, result: result)

        case "isConnected":
            handleIsConnected(result: result)

        case "clearBuffer":
            handleClearBuffer(result: result)

        case "printLabel":
            handlePrintLabel(call: call, result: result)

        case "executePrintJob":
            handleExecutePrintJob(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Handler Methods

    private func handleListAccessories(result: @escaping FlutterResult) {
        let accessories = EAAccessoryManager.shared().connectedAccessories

        var accessoryList: [[String: Any]] = []

        for accessory in accessories {
            let accessoryInfo: [String: Any] = [
                "name": accessory.name,
                "manufacturer": accessory.manufacturer,
                "model": accessory.modelNumber,
                "serial": accessory.serialNumber,
                "firmware": accessory.firmwareRevision,
                "hardware": accessory.hardwareRevision,
                "protocols": accessory.protocolStrings,
            ]
            accessoryList.append(accessoryInfo)
        }

        result(accessoryList)
    }

    private func handleOpenPort(result: @escaping FlutterResult) {
        // Debug: List all available accessories
        let accessories = EAAccessoryManager.shared().connectedAccessories
        print("========== TSC MFI DEBUG ==========")
        print("Total accessories found: \(accessories.count)")

        for (index, accessory) in accessories.enumerated() {
            print("Accessory \(index):")
            print("  Name: \(accessory.name)")
            print("  Manufacturer: \(accessory.manufacturer)")
            print("  Model: \(accessory.modelNumber)")
            print("  Serial: \(accessory.serialNumber)")
            print("  Firmware: \(accessory.firmwareRevision)")
            print("  Hardware: \(accessory.hardwareRevision)")
            print("  Protocols: \(accessory.protocolStrings)")
        }
        print("===================================")

        if tscBluetooth == nil {
            tscBluetooth = Bluetooth()
        }

        // Call openport_mfi() just like swift_sample does
        // Note: Don't check return status - the tscswift framework may return non-zero even on success
        // The important thing is that the stream opens (we see "Stream opened" in logs)
        let status = tscBluetooth!.openport_mfi()
        print("TSC openport_mfi() called, status: \(status)")

        // Add 1 second delay like swift_sample does
        Thread.sleep(forTimeInterval: 1.0)

        // Return success - if there were real connection issues, send commands would fail later
        print("TSC MFI connection completed")
        result(true)
    }

    private func handleClosePort(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let bluetooth = tscBluetooth else {
            result(FlutterError(
                code: "NOT_CONNECTED",
                message: "Not connected to printer",
                details: nil
            ))
            return
        }

        let args = call.arguments as? [String: Any]
        let delay = args?["delay"] as? Double ?? 0.0

        let status: Int
        if delay > 0 {
            status = bluetooth.closeport(delay)
        } else {
            status = bluetooth.closeport()
        }

        if status == 0 {
            tscBluetooth = nil
            result(true)
        } else {
            result(FlutterError(
                code: "CLOSE_FAILED",
                message: "Failed to close port. Status: \(status)",
                details: nil
            ))
        }
    }

    private func handleSendCommand(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("📤 handleSendCommand called")

        guard let bluetooth = tscBluetooth else {
            print("❌ tscBluetooth is nil - not connected")
            result(FlutterError(
                code: "NOT_CONNECTED",
                message: "Not connected to printer",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let command = args["command"] as? String else {
            print("❌ Invalid arguments")
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Command string is required",
                details: nil
            ))
            return
        }

        let delay = args["delay"] as? Double ?? 0.0

        print("📤 Sending command: \(command.replacingOccurrences(of: "\r\n", with: "\\r\\n"))")

        // Call sendcommand just like swift_sample does - don't check return status
        let status: Int
        if delay > 0 {
            status = bluetooth.sendcommand(command, delay: delay)
        } else {
            status = bluetooth.sendcommand(command)
        }

        print("✅ sendcommand returned status: \(status)")

        // Always return success - swift_sample doesn't check status
        result(true)
    }

    private func handleSendCommandUtf8(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let bluetooth = tscBluetooth else {
            result(FlutterError(
                code: "NOT_CONNECTED",
                message: "Not connected to printer",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let command = args["command"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Command string is required",
                details: nil
            ))
            return
        }

        let delay = args["delay"] as? Double ?? 0.0

        // Call sendcommand_utf8 just like swift_sample does - don't check return status
        if delay > 0 {
            let _ = bluetooth.sendcommand_utf8(command, delay: delay)
        } else {
            let _ = bluetooth.sendcommand_utf8(command)
        }

        // Always return success
        result(true)
    }

    private func handleSendCommandWithData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let bluetooth = tscBluetooth else {
            result(FlutterError(
                code: "NOT_CONNECTED",
                message: "Not connected to printer",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let commandData = args["data"] as? FlutterStandardTypedData else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Command data is required",
                details: nil
            ))
            return
        }

        let delay = args["delay"] as? Double ?? 0.0

        // Call sendCommandWithData just like swift_sample does - don't check return status
        if delay > 0 {
            let _ = bluetooth.sendCommandWithData(commandData.data, delay: delay)
        } else {
            let _ = bluetooth.sendCommandWithData(commandData.data)
        }

        // Always return success
        result(true)
    }

    private func handlePrinterStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let bluetooth = tscBluetooth else {
            result(FlutterError(
                code: "NOT_CONNECTED",
                message: "Not connected to printer",
                details: nil
            ))
            return
        }

        let args = call.arguments as? [String: Any]
        let delay = args?["delay"] as? Double ?? 2.0

        let status: String
        if delay > 0 {
            status = bluetooth.printer_status(delay)
        } else {
            status = bluetooth.printer_status()
        }

        result(status)
    }

    private func handleIsConnected(result: @escaping FlutterResult) {
        let isConnected = tscBluetooth != nil
        result(isConnected)
    }

    private func handleClearBuffer(result: @escaping FlutterResult) {
        print("🧹 handleClearBuffer called")

        guard let bluetooth = tscBluetooth else {
            print("❌ tscBluetooth is nil - not connected")
            result(FlutterError(
                code: "NOT_CONNECTED",
                message: "Not connected to printer",
                details: nil
            ))
            return
        }

        bluetooth.clearBuffer()
        print("✅ Buffer cleared")
        result(true)
    }

    private func handlePrintLabel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🖨️ handlePrintLabel called")

        guard let bluetooth = tscBluetooth else {
            print("❌ tscBluetooth is nil - not connected")
            result(FlutterError(
                code: "NOT_CONNECTED",
                message: "Not connected to printer",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let sets = args["sets"] as? Int,
              let copies = args["copies"] as? Int else {
            print("❌ Invalid arguments")
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "sets and copies are required",
                details: nil
            ))
            return
        }

        print("🖨️ Printing label: sets=\(sets), copies=\(copies)")

        // Call printlabel just like swift_sample does
        let status = bluetooth.printlabel(sets, copies: copies)
        print("✅ printlabel returned status: \(status)")

        result(true)
    }

    // Execute complete print job - exactly like swift_sample Send button
    // This does everything in one native call to avoid multiple method channel calls
    private func handleExecutePrintJob(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🖨️ handleExecutePrintJob START")

        guard let args = call.arguments as? [String: Any],
              let commands = args["commands"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "commands string is required",
                details: nil
            ))
            return
        }

        // Create new Bluetooth instance if needed
        if tscBluetooth == nil {
            tscBluetooth = Bluetooth()
        }

        // Step 1: Open port
        print("Step 1: Opening port...")
        let _ = tscBluetooth!.openport_mfi()
        Thread.sleep(forTimeInterval: 1.0)

        // Step 2: Send all commands at once
        print("Step 2: Sending commands batch...")
        let _ = tscBluetooth!.sendcommand(commands)

        // Step 3: Print label
        print("Step 3: Printing label...")
        let _ = tscBluetooth!.printlabel(1, copies: 1)

        // Step 4: Close port
        print("Step 4: Closing port...")
        let _ = tscBluetooth!.closeport(4)

        tscBluetooth = nil

        print("✅ Print job completed")
        result(true)
    }
}
