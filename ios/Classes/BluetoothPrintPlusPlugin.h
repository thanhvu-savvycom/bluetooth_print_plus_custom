#import <Flutter/Flutter.h>
#import <CoreBluetooth/CoreBluetooth.h>

#if TARGET_OS_SIMULATOR
// GSDK not available on simulator - define placeholders
#ifndef CONNECT_STATE_DEFINED
#define CONNECT_STATE_DEFINED
typedef NS_ENUM(NSInteger, ConnectState) {
    CONNECT_STATE_DISCONNECT = 0,
    CONNECT_STATE_CONNECTING = 1,
    CONNECT_STATE_CONNECTED = 2,
    CONNECT_STATE_TIMEOUT = 3,
    CONNECT_STATE_FAILT = 4
};
typedef void (^ConnectDeviceState)(ConnectState state);
#endif
#else
#import <GSDK/BLEConnecter.h>
#endif

@interface BluetoothPrintPlusPlugin : NSObject<FlutterPlugin>

@property(nonatomic,copy) ConnectDeviceState state;

@end

@interface BluetoothPrintStreamHandler : NSObject<FlutterStreamHandler>

@property FlutterEventSink sink;

@end
