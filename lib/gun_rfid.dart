import 'dart:async';

import 'package:flutter/services.dart';

// 类型定义 - 接收函数
typedef TypeOnRecvData = void Function(Map<Object?, Object?> value);

class GunRfid {
  // 事件通道
  static const EventChannel eventChannel =
      EventChannel('net.pericles.gun_rfid/eventChannel');

  static const MethodChannel _channel = MethodChannel('gun_rfid');

  // 按键通道
  final MethodChannel methodChannel =
      const MethodChannel('net.pericles.gun_rfid/keyMethodChannel');

  // 接收函数
  TypeOnRecvData? _onRecvData;

  // 订阅
  StreamSubscription? _streamSubscription;

  // 获取平台版本·
  Future<String?> getPlatformVersion() {
    return _channel.invokeMethod("getPlatformVersion");
  }

  // 获取连接状态
  Future<bool> getConnectState() async {
    return await _channel.invokeMethod("getConnectState");
  }

  // 初始化RFID
  Future<bool> initRFID() async {
    return await _channel.invokeMethod("initRFID");
  }

  // 关闭RFID
  Future<bool> closeRFID() async {
    stopInventory();
    return await _channel.invokeMethod("closeRFID");
  }

  //重启模块
  Future<bool> restartRFID() async {
    bool reStartFlage = false;
    bool? isColed = await _channel.invokeMethod("closeRFID");
    if (isColed == true) {
      reStartFlage = await _channel.invokeMethod("initRFID");
    }
    return reStartFlage;
  }

  // 读取RFID
  Future<void> startInventory(TypeOnRecvData onRecvData) async {
    _onRecvData = onRecvData;
    bool? isStarting = await _channel.invokeMethod("startInventory");
    if (isStarting == true) {
      _streamSubscription =
          eventChannel.receiveBroadcastStream().listen((event) {
        _onRecvData?.call(event);
      });
    }
  }

  // 取消盘点
  void stopInventory() async {
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }
    if (_onRecvData != null) {
      _onRecvData = null;
    }
  }

  // 注册按键监听
  Future<bool> registerKey() async {
    return await _channel.invokeMethod("registerKey");
  }

  // 注销按键监听
  Future<bool> unregisterKey() async {
    return await _channel.invokeMethod("unregisterKey");
  }

  //获取当前读取状态
  Future<bool> getReadState() async {
    return await _channel.invokeMethod("isReader");
  }

  //获取按键是否被注册
  Future<bool> getKeyState() async {
    return await _channel.invokeMethod("checkKeyStatus");
  }

  // 按键读取RFID
  Future<void> keyStartInventory(TypeOnRecvData onRecvData) async {
    methodChannel.setMethodCallHandler((call) async {
      //print("android調用flutter方法:${call.method}");
      if (call.method == 'startInventoryFromKeyEvent') {
        _onRecvData = onRecvData;
        bool? isStarting = await _channel.invokeMethod("startInventory");
        //print("isStarting:$isStarting");
        if (isStarting == true) {
          _streamSubscription =
              eventChannel.receiveBroadcastStream().listen((event) {
            _onRecvData?.call(event);
          });
        }
      }
      if (call.method == 'stopInventoryFromKeyEvent') {
        stopInventory();
      }
    });
  }

  //设置过滤
  Future<bool> setFilter(String filter) async {
    return await _channel.invokeMethod("setFilter", {"filter": filter});
  }

  //设置功率
  Future<bool> setPower(int power) async {
    return await _channel.invokeMethod("setPower", {"power": power});
  }

  //修改EPC编码
  Future<bool> editEPC(String oldEPC, String newEPC) async {
    return await _channel.invokeMethod("editEPC", {
      "oldEPC": oldEPC,
      "newEPC": newEPC,
    });
  }

  // 释放资源
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
