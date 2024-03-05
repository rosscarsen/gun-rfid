import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gun_rfid_platform_interface.dart';

/// An implementation of [GunRfidPlatform] that uses method channels.
class MethodChannelGunRfid extends GunRfidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('gun_rfid');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
