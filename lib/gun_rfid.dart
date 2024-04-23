import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Type definition for the receive data function
typedef TypeOnRecvData = void Function(Map<Object?, Object?> value);

class GunRfid {
  // Event channel
  static const EventChannel eventChannel =
      EventChannel('net.pericles.gun_rfid/eventChannel');

  static const MethodChannel _channel = MethodChannel('gun_rfid');

  // Method channel for keys
  final MethodChannel methodChannel =
      const MethodChannel('net.pericles.gun_rfid/keyMethodChannel');

  // Receive data function
  TypeOnRecvData? _onRecvData;

  // Subscription for the stream
  StreamSubscription? _streamSubscription;

  // Get the platform version
  Future<String?> getPlatformVersion() async {
    try {
      return await _channel.invokeMethod("getPlatformVersion");
    } catch (e) {
      debugPrint("Error getting platform version: $e");
      return null;
    }
  }

  // Get the connection state
  Future<bool> getConnectState() async {
    try {
      return await _channel.invokeMethod("getConnectState");
    } catch (e) {
      debugPrint("Error getting connection state: $e");
      return false;
    }
  }

  // Initialize RFID
  Future<bool> initRFID() async {
    try {
      return await _channel.invokeMethod("initRFID");
    } catch (e) {
      debugPrint("Error initializing RFID: $e");
      return false;
    }
  }

  // Close RFID
  Future<bool> closeRFID() async {
    stopInventory();
    try {
      return await _channel.invokeMethod("closeRFID");
    } catch (e) {
      debugPrint("Error closing RFID: $e");
      return false;
    }
  }

  // Restart RFID module
  Future<bool> restartRFID() async {
    try {
      bool? isClosed = await _channel.invokeMethod("closeRFID");
      if (isClosed == true) {
        return await _channel.invokeMethod("initRFID");
      }
      return false;
    } catch (e) {
      debugPrint("Error restarting RFID: $e");
      return false;
    }
  }

  // Start inventory
  Future<void> startInventory(TypeOnRecvData onRecvData) async {
    _onRecvData = onRecvData;
    try {
      bool? isStarting = await _channel.invokeMethod("startInventory");
      if (isStarting == true) {
        _streamSubscription =
            eventChannel.receiveBroadcastStream().listen((event) {
          _onRecvData?.call(event);
        }, onError: (err) {
          debugPrint("Error during inventory start: $err");
          _streamSubscription?.cancel();
        });
      }
    } catch (e) {
      debugPrint("Error starting inventory: $e");
    }
  }

  // Stop inventory
  void stopInventory() async {
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }
    if (_onRecvData != null) {
      _onRecvData = null;
    }
  }

  // Register key
  Future<bool> registerKey() async {
    try {
      return await _channel.invokeMethod("registerKey");
    } catch (e) {
      debugPrint("Error registering key: $e");
      return false;
    }
  }

  // Unregister key
  Future<bool> unregisterKey() async {
    try {
      return await _channel.invokeMethod("unregisterKey");
    } catch (e) {
      debugPrint("Error unregistering key: $e");
      return false;
    }
  }

  // Get the current read state
  Future<bool> getReadState() async {
    try {
      return await _channel.invokeMethod("isReader");
    } catch (e) {
      debugPrint("Error getting read state: $e");
      return false;
    }
  }

  // Get the key registration state
  Future<bool> getKeyState() async {
    try {
      return await _channel.invokeMethod("checkKeyStatus");
    } catch (e) {
      debugPrint("Error getting key state: $e");
      return false;
    }
  }

  // Key event based start of inventory
  Future<void> keyStartInventory(TypeOnRecvData onRecvData) async {
    methodChannel.setMethodCallHandler((call) async {
      try {
        if (call.method == 'startInventoryFromKeyEvent') {
          _onRecvData = onRecvData;
          bool? isStarting = await _channel.invokeMethod("startInventory");
          if (isStarting == true) {
            _streamSubscription =
                eventChannel.receiveBroadcastStream().listen((event) {
              _onRecvData?.call(event);
            }, onError: (err) {
              debugPrint("Error during inventory start from key event: $err");
              _streamSubscription?.cancel();
            });
          }
        }
        if (call.method == 'stopInventoryFromKeyEvent') {
          stopInventory();
        }
      } catch (e) {
        debugPrint("Error handling method call: $e");
      }
    });
  }

  // Set filter
  Future<bool> setFilter(String filter) async {
    try {
      return await _channel.invokeMethod("setFilter", {"filter": filter});
    } catch (e) {
      debugPrint("Error setting filter: $e");
      return false;
    }
  }

  // Set power
  Future<bool> setPower(int power) async {
    try {
      return await _channel.invokeMethod("setPower", {"power": power});
    } catch (e) {
      debugPrint("Error setting power: $e");
      return false;
    }
  }

  // Edit EPC code
  Future<bool> editEPC(String oldEPC, String newEPC) async {
    try {
      return await _channel.invokeMethod("editEPC", {
        "oldEPC": oldEPC,
        "newEPC": newEPC,
      });
    } catch (e) {
      debugPrint("Error editing EPC: $e");
      return false;
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }
    if (_onRecvData != null) {
      _onRecvData = null;
    }
  }
}
