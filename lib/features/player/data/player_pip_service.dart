import 'package:flutter/services.dart';

final class PlayerPipService {
  const PlayerPipService._();

  static const _channel = MethodChannel('dream_cast/player_pip');

  static void setModeChangedHandler(ValueChanged<bool>? onChanged) {
    if (onChanged == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'changed') return null;
      final arguments = call.arguments;
      final active = arguments is Map && arguments['active'] is bool
          ? arguments['active'] as bool
          : false;
      onChanged(active);
      return null;
    });
  }

  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> setEnabled({
    required bool enabled,
    double aspectRatio = 16 / 9,
  }) async {
    try {
      final safeRatio = aspectRatio.isFinite && aspectRatio > 0
          ? aspectRatio
          : 16 / 9;
      await _channel.invokeMethod<void>('setEnabled', {
        'enabled': enabled,
        'width': (safeRatio * 1000).round().clamp(1, 10000),
        'height': 1000,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<bool> enter() async {
    try {
      return await _channel.invokeMethod<bool>('enter') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
