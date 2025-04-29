import 'package:flutter/services.dart';

class PoseBridge {
  static const platform = MethodChannel('mediapipe/pose');

  static Future<String> runPoseEstimation(String videoPath) async {
    try {
      final result = await platform.invokeMethod('analyzePose', {
        'videoPath': videoPath,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to get pose: '[38;5;1m${e.message}[0m'.");
      return '{}';
    }
  }
} 