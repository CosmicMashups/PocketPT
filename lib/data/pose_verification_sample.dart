import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

/// Represents a stored inference frame exported from `pose_test.py`.
class PoseVerificationSample {
  PoseVerificationSample({
    required this.frameId,
    required this.imageSize,
    required this.expectedScale,
    required this.expectedPadX,
    required this.expectedPadY,
    required this.keypoints,
  });

  final String frameId;
  final Size imageSize;
  final double expectedScale;
  final double expectedPadX;
  final double expectedPadY;
  final List<Map<String, dynamic>> keypoints;

  static Future<PoseVerificationSample> loadFromAsset(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final kp = (data['keypoints'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((entry) => {
              'name': entry['name'],
              'x': (entry['x'] as num).toDouble(),
              'y': (entry['y'] as num).toDouble(),
              'confidence': (entry['confidence'] as num).toDouble(),
              'index': entry['index'] as int,
            })
        .toList(growable: false);

    return PoseVerificationSample(
      frameId: data['frameId'] as String,
      imageSize: Size(
        (data['originalWidth'] as num).toDouble(),
        (data['originalHeight'] as num).toDouble(),
      ),
      expectedScale: (data['expectedScale'] as num).toDouble(),
      expectedPadX: (data['expectedPadX'] as num).toDouble(),
      expectedPadY: (data['expectedPadY'] as num).toDouble(),
      keypoints: kp,
    );
  }

  /// Simple validation hook to ensure the preprocessing constants we use in
  /// Dart match the metadata exported alongside the sample.
  ///
  /// Returns true if scale/padding match within tolerance.
  bool validateScaleAndPadding({
    required double computedScale,
    required double computedPadX,
    required double computedPadY,
    double tolerance = 0.5,
  }) {
    double diff(double a, double b) => (a - b).abs();

    final scaleMatches = diff(computedScale, expectedScale) <= tolerance;
    final padXMatches = diff(computedPadX, expectedPadX) <= tolerance;
    final padYMatches = diff(computedPadY, expectedPadY) <= tolerance;

    return scaleMatches && padXMatches && padYMatches;
  }
}

