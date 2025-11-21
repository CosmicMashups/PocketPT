import 'package:flutter/foundation.dart';

/// Centralized diagnostics helper for pose estimation.
///
/// Captures model initialization status, tensor statistics, and frame streaks
/// so UI layers can surface actionable warnings when no skeleton is rendered.
class PoseDiagnostics {
  PoseDiagnostics._();

  static final PoseDiagnostics instance = PoseDiagnostics._();

  /// Whether verbose logging should be emitted via debugPrint.
  ///
  /// Defaults to true in debug/profile builds.
  final bool loggingEnabled = !kReleaseMode;

  final ValueNotifier<PoseDiagnosticSnapshot> snapshot =
      ValueNotifier(PoseDiagnosticSnapshot.initial());

  int _emptyFrameStreak = 0;

  void logModelInit({required bool success, String? message}) {
    if (loggingEnabled) {
      debugPrint(
        '[PoseDiagnostics] Model init ${success ? "✓" : "✗"}: '
        '${message ?? "ready"}',
      );
    }

    snapshot.value = snapshot.value.copyWith(
      modelInitialized: success,
      modelError: success ? null : message ?? 'Unknown error',
      lastWarning: success ? null : 'Model initialization failed',
      lastUpdated: DateTime.now(),
    );
  }

  void logInputTensor(Float32List data, List<int> shape) {
    final stats = _tensorStats(data);
    if (loggingEnabled) {
      debugPrint(
        '[PoseDiagnostics] Input tensor shape=$shape '
        'min=${stats.min.toStringAsFixed(4)} '
        'max=${stats.max.toStringAsFixed(4)} '
        'mean=${stats.mean.toStringAsFixed(4)}',
      );
    }

    snapshot.value = snapshot.value.copyWith(
      lastInputShape: shape,
      lastInputStats: stats,
      lastUpdated: DateTime.now(),
    );
  }

  void logOutputKeypoints(
    List<Map<String, dynamic>> keypoints, {
    Duration? duration,
  }) {
    final count = keypoints.length;
    _emptyFrameStreak = count == 0 ? _emptyFrameStreak + 1 : 0;

    if (loggingEnabled) {
      final first = keypoints.isEmpty ? null : keypoints.first;
      debugPrint(
        '[PoseDiagnostics] Output keypoints=$count '
        '${first != null ? "sample=${first["name"]}@(${first["x"]?.toStringAsFixed(1)}, ${first["y"]?.toStringAsFixed(1)})" : ""} '
        '${duration != null ? "duration=${duration.inMilliseconds}ms" : ""}',
      );
    }

    snapshot.value = snapshot.value.copyWith(
      lastKeypointCount: count,
      emptyFrameStreak: _emptyFrameStreak,
      lastInferenceMs: duration?.inMilliseconds.toDouble(),
      lastUpdated: DateTime.now(),
      lastWarning: _emptyFrameStreak >= PoseDiagnosticSnapshot.emptyFrameThreshold
          ? 'No pose detected for $_emptyFrameStreak frames'
          : null,
    );
  }

  void markFrameFailure(String reason) {
    _emptyFrameStreak++;
    if (loggingEnabled) {
      debugPrint('[PoseDiagnostics] Frame failure: $reason');
    }

    snapshot.value = snapshot.value.copyWith(
      emptyFrameStreak: _emptyFrameStreak,
      lastWarning: reason,
      lastUpdated: DateTime.now(),
    );
  }

  void resetFrameStreak() {
    _emptyFrameStreak = 0;
    snapshot.value = snapshot.value.copyWith(
      emptyFrameStreak: 0,
      lastWarning: null,
      lastUpdated: DateTime.now(),
    );
  }

  PoseTensorStats _tensorStats(Float32List data) {
    if (data.isEmpty) {
      return const PoseTensorStats(min: 0, max: 0, mean: 0);
    }

    var minVal = double.infinity;
    var maxVal = -double.infinity;
    double sum = 0;

    for (final value in data) {
      if (value < minVal) minVal = value;
      if (value > maxVal) maxVal = value;
      sum += value;
    }

    return PoseTensorStats(
      min: minVal,
      max: maxVal,
      mean: sum / data.length,
    );
  }
}

@immutable
class PoseDiagnosticSnapshot {
  const PoseDiagnosticSnapshot({
    required this.modelInitialized,
    required this.emptyFrameStreak,
    required this.lastUpdated,
    this.modelError,
    this.lastWarning,
    this.lastKeypointCount,
    this.lastInferenceMs,
    this.lastInputShape,
    this.lastInputStats,
  });

  static const emptyFrameThreshold = 18;

  final bool modelInitialized;
  final int emptyFrameStreak;
  final DateTime lastUpdated;
  final String? modelError;
  final String? lastWarning;
  final int? lastKeypointCount;
  final double? lastInferenceMs;
  final List<int>? lastInputShape;
  final PoseTensorStats? lastInputStats;

  factory PoseDiagnosticSnapshot.initial() => PoseDiagnosticSnapshot(
        modelInitialized: false,
        emptyFrameStreak: 0,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
      );

  PoseDiagnosticSnapshot copyWith({
    bool? modelInitialized,
    int? emptyFrameStreak,
    DateTime? lastUpdated,
    String? modelError,
    String? lastWarning,
    int? lastKeypointCount,
    double? lastInferenceMs,
    List<int>? lastInputShape,
    PoseTensorStats? lastInputStats,
  }) {
    return PoseDiagnosticSnapshot(
      modelInitialized: modelInitialized ?? this.modelInitialized,
      emptyFrameStreak: emptyFrameStreak ?? this.emptyFrameStreak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      modelError: modelError ?? this.modelError,
      lastWarning: lastWarning,
      lastKeypointCount: lastKeypointCount ?? this.lastKeypointCount,
      lastInferenceMs: lastInferenceMs ?? this.lastInferenceMs,
      lastInputShape: lastInputShape ?? this.lastInputShape,
      lastInputStats: lastInputStats ?? this.lastInputStats,
    );
  }
}

@immutable
class PoseTensorStats {
  const PoseTensorStats({
    required this.min,
    required this.max,
    required this.mean,
  });

  final double min;
  final double max;
  final double mean;

  Map<String, double> toJson() => {
        'min': min,
        'max': max,
        'mean': mean,
      };
}

