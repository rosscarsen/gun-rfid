import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'gun_rfid_method_channel.dart';

abstract class GunRfidPlatform extends PlatformInterface {
  /// Constructs a GunRfidPlatform.
  GunRfidPlatform() : super(token: _token);

  static final Object _token = Object();

  static GunRfidPlatform _instance = MethodChannelGunRfid();

  /// The default instance of [GunRfidPlatform] to use.
  ///
  /// Defaults to [MethodChannelGunRfid].
  static GunRfidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GunRfidPlatform] when
  /// they register themselves.
  static set instance(GunRfidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
