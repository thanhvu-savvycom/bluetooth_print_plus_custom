import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/services.dart';

import 'function_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothDevice? _device;
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<BlueState> _blueStateSubscription;
  late StreamSubscription<ConnectState> _connectStateSubscription;
  late StreamSubscription<Uint8List> _receivedDataSubscription;
  late StreamSubscription<List<BluetoothDevice>> _scanResultsSubscription;
  List<BluetoothDevice> _scanResults = [];

  @override
  void initState() {
    super.initState();
    initBluetoothPrintPlusListen();
  }

  @override
  void dispose() {
    super.dispose();
    _isScanningSubscription.cancel();
    _blueStateSubscription.cancel();
    _connectStateSubscription.cancel();
    _receivedDataSubscription.cancel();
    _scanResultsSubscription.cancel();
    _scanResults.clear();
  }

  Future<void> initBluetoothPrintPlusListen() async {
    /// listen scanResults
    _scanResultsSubscription = BluetoothPrintPlus.scanResults.listen((event) {
      if (mounted) {
        setState(() {
          _scanResults = event;
        });
      }
    });

    /// listen isScanning
    _isScanningSubscription = BluetoothPrintPlus.isScanning.listen((event) {
      print('********** isScanning: $event **********');
      if (mounted) {
        setState(() {});
      }
    });

    /// listen blue state
    _blueStateSubscription = BluetoothPrintPlus.blueState.listen((event) {
      print('********** blueState change: $event **********');
      if (mounted) {
        setState(() {});
      }
    });

    /// listen connect state
    _connectStateSubscription = BluetoothPrintPlus.connectState.listen((event) {
      print('********** connectState change: $event **********');
      switch (event) {
        case ConnectState.connected:
          setState(() {
            if (_device == null) return;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FunctionPage(_device!)));
          });
          break;
        case ConnectState.disconnected:
          setState(() {
            _device = null;
          });
          break;
      }
    });

    /// listen received data
    _receivedDataSubscription = BluetoothPrintPlus.receivedData.listen((data) {
      print('********** received data: $data **********');

      /// do something...
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('BluetoothPrintPlus'),
        ),
        body: SafeArea(
            child: BluetoothPrintPlus.isBlueOn
                ? ListView(
                    children: [
                      // iOS MFI Section
                      if (Platform.isIOS) ...[
                        TscMfiSection(),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Text(
                            'BLE Devices (Standard Bluetooth)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                      // BLE devices list
                      ..._scanResults
                          .map((device) => Container(
                                padding: EdgeInsets.only(
                                    left: 10, right: 10, bottom: 5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(device.name),
                                        Text(
                                          device.address,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        Divider(),
                                      ],
                                    )),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    OutlinedButton(
                                      onPressed: () async {
                                        _device = device;
                                        await BluetoothPrintPlus.connect(
                                            device);
                                      },
                                      child: const Text("connect"),
                                    )
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  )
                : buildBlueOffWidget()),
        floatingActionButton:
            BluetoothPrintPlus.isBlueOn ? buildScanButton(context) : null);
  }

  Widget buildBlueOffWidget() {
    return Center(
        child: Text(
      "Bluetooth is turned off\nPlease turn on Bluetooth...",
      style: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 16, color: Colors.red),
      textAlign: TextAlign.center,
    ));
  }

  Widget buildScanButton(BuildContext context) {
    if (BluetoothPrintPlus.isScanningNow) {
      return FloatingActionButton(
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
        child: Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
          onPressed: onScanPressed,
          backgroundColor: Colors.green,
          child: Text("SCAN"));
    }
  }

  Future onScanPressed() async {
    try {
      await BluetoothPrintPlus.startScan(timeout: Duration(seconds: 10));
    } catch (e) {
      print("onScanPressed error: $e");
    }
  }

  Future onStopPressed() async {
    try {
      BluetoothPrintPlus.stopScan();
    } catch (e) {
      print("onStopPressed error: $e");
    }
  }
}

/// TSC MFI Section Widget
/// Handles TSC printer connection via iOS MFI (External Accessory)
class TscMfiSection extends StatefulWidget {
  const TscMfiSection({super.key});

  @override
  State<TscMfiSection> createState() => _TscMfiSectionState();
}

class _TscMfiSectionState extends State<TscMfiSection> {
  List<Map<String, dynamic>> _accessories = [];
  bool _isConnected = false;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAccessories();
  }

  Future<void> _checkAccessories() async {
    try {
      final accessories = await TscMfiChannel.listAccessories();
      setState(() {
        _accessories = accessories;
      });
    } catch (e) {
      print('Error listing accessories: $e');
    }
  }

  Future<void> _connectToMfi() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting...';
    });

    try {
      final connected = await TscMfiChannel.openPortMfi();

      setState(() {
        _isConnected = connected;
        _isLoading = false;
        _statusMessage =
            connected ? 'Connected successfully' : 'Connection failed';
      });

      if (connected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to TSC Printer'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printDemo() async {
    print('========== _printDemo() START ==========');

    try {
      // Build ALL commands in one buffer
      final StringBuffer commands = StringBuffer();

      // Setup (exactly like swift_sample)
      commands.write('DIRECTION 1\r\n');
      commands.write('SIZE 72 mm, 25 mm\r\n');
      commands.write('SPEED 4\r\n');
      commands.write('DENSITY 10\r\n');
      commands.write('GAP 0 mm, 0 mm\r\n');
      commands.write('CLS\r\n');

      // Content
      commands.write('TEXT 30,30,"2",0,2,2,"1234567"\r\n');
      commands.write('TEXT 30,100,"2",0,2,2,"Test Print"\r\n');

      // Execute complete print job with ONE native call
      // This does: open → commands → print → close
      print('Executing print job...');
      await TscMfiChannel.executePrintJob(commands.toString());

      print('✅ Print completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('========== PRINT ERROR ==========');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('==================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.print, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'TSC Printer (iOS MFI)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Instructions
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Instructions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '1. Go to Settings → Bluetooth\n'
                  '2. Find and connect to your TSC printer\n'
                  '3. Return to this app\n'
                  '4. Tap "Print Demo" button below',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // Accessories found
          if (_accessories.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Device Found',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ..._accessories.map((acc) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${acc['name']}',
                              style: TextStyle(fontSize: 12)),
                          Text('Manufacturer: ${acc['manufacturer']}',
                              style: TextStyle(fontSize: 12)),
                          Text('Model: ${acc['model']}',
                              style: TextStyle(fontSize: 12)),
                        ],
                      )),
                ],
              ),
            ),
            SizedBox(height: 12),
          ] else ...[
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No device connected. Please connect in Settings.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],

          // Action buttons - Simple and direct like swift_sample
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checkAccessories,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade900,
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _accessories.isEmpty ? null : _printDemo,
                  icon: Icon(Icons.print, size: 18),
                  label: Text('Print Demo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
