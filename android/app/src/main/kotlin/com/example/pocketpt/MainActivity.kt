package com.example.pocketpt

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "mediapipe/pose"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "analyzePose" -> {
                    val videoPath = call.argument<String>("videoPath")
                    if (videoPath == null) {
                        result.error("INVALID_ARGUMENT", "Video path cannot be null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val poseJson = runMediaPipePose(videoPath)
                        result.success(poseJson)
                    } catch (e: Exception) {
                        result.error("POSE_ANALYSIS_ERROR", e.message, e.stackTraceToString())
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun runMediaPipePose(videoPath: String): String {
        // TODO: Implement actual MediaPipe pose estimation
        // For now, return dummy data in the expected format
        return """
        {
            "frames": [
                {
                    "frame": 1,
                    "landmarks": [
                        {"x": 0.45, "y": 0.32, "z": 0.0, "visibility": 0.98, "name": "LEFT_SHOULDER"},
                        {"x": 0.55, "y": 0.35, "z": 0.0, "visibility": 0.96, "name": "RIGHT_SHOULDER"},
                        {"x": 0.47, "y": 0.62, "z": 0.0, "visibility": 0.94, "name": "LEFT_HIP"},
                        {"x": 0.53, "y": 0.62, "z": 0.0, "visibility": 0.95, "name": "RIGHT_HIP"}
                    ]
                }
            ]
        }
        """.trimIndent()
    }
}
