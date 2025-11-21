package com.example.pocketpt

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import ai.onnxruntime.*
import org.pytorch.Module
import org.pytorch.IValue
import org.pytorch.Tensor
import android.util.Log
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val POSE_CHANNEL = "com.pocketpt/onnxruntime"

    private val PAIN_CHANNEL = "com.pocketpt/onnxruntime-pain"
    private val PYTORCH_CHANNEL = "com.pocketpt/pytorch"
    private var poseSession: OrtSession? = null
    private var painSession: OrtSession? = null
    private var pytorchModule: Module? = null
    private var ortEnv: OrtEnvironment? = null


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (e: Exception) {
            Log.e("PocketPT", "Error registering plugins", e)
        }
        
        ortEnv = OrtEnvironment.getEnvironment()
        
        // Pose estimation model channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POSE_CHANNEL).setMethodCallHandler { call, result ->
            handleOnnxMethodCall(call, result, { poseSession }, { poseSession = it }, "images")
        }
        
        // Pain detection model channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PAIN_CHANNEL).setMethodCallHandler { call, result ->
            handleOnnxMethodCall(call, result, { painSession }, { painSession = it }, "input")
        }

        // PyTorch model channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PYTORCH_CHANNEL).setMethodCallHandler { call, result ->
            handlePyTorchMethodCall(call, result)
        }
    }
    
    private fun handleOnnxMethodCall(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
        getSession: () -> OrtSession?,
        setSession: (OrtSession?) -> Unit,
        inputName: String
    ) {
        when (call.method) {
            "initialize" -> {
                try {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath == null) {
                        result.error("INVALID_ARGUMENT", "modelPath is required", null)
                        return
                    }
                    
                    val sessionOptions = OrtSession.SessionOptions()
                    val session = ortEnv!!.createSession(modelPath, sessionOptions)
                    setSession(session)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INIT_ERROR", e.message, null)
                }
            }
            "run" -> {
                try {
                    val session = getSession()
                    if (session == null) {
                        result.error("NOT_INITIALIZED", "Session not initialized", null)
                        return
                    }

                    val validated = validateInputTensor(
                        call.argument<FloatArray>("input"),
                        call.argument("inputShape"),
                        result
                    ) ?: return
                    val (floatArray, shape) = validated

                    // Create ByteBuffer from FloatArray
                    val buffer = java.nio.ByteBuffer.allocate(floatArray.size * 4).order(java.nio.ByteOrder.nativeOrder())
                    buffer.asFloatBuffer().put(floatArray)
                    buffer.rewind()
                    val inputTensor = OnnxTensor.createTensor(ortEnv!!, buffer, shape)
                    
                    // Run inference
                    val inputs = mapOf(inputName to inputTensor)
                    val outputs = session.run(inputs)
                    
                    // Get output tensor
                    val outputTensor = outputs[0].value as OnnxTensor
                    val outputBuffer = outputTensor.floatBuffer
                    val outputArray = FloatArray(outputBuffer.remaining())
                    outputBuffer.get(outputArray)
                    
                    // Convert to List<Double> for return to Dart
                    val outputList = outputArray.map { it.toDouble() }.toList()
                    
                    // Clean up
                    inputTensor.close()
                    outputTensor.close()
                    outputs.close()
                    
                    result.success(outputList)
                } catch (e: Exception) {
                    result.error("INFERENCE_ERROR", e.message, null)
                }
            }
            "dispose" -> {
                try {
                    getSession()?.close()
                    setSession(null)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("DISPOSE_ERROR", e.message, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        poseSession?.close()
        painSession?.close()
    }
    private fun handlePyTorchMethodCall(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "initialize" -> {
                try {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath == null) {
                        result.error("INVALID_ARGUMENT", "modelPath is required", null)
                        return
                    }
                    
                    pytorchModule = Module.load(modelPath)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INIT_ERROR", e.message, null)
                }
            }
            "run" -> {
                try {
                    if (pytorchModule == null) {
                        result.error("NOT_INITIALIZED", "Module not initialized", null)
                        return
                    }

                    val validated = validateInputTensor(
                        call.argument<FloatArray>("input"),
                        call.argument("inputShape"),
                        result
                    ) ?: return
                    val (floatArray, shape) = validated

                    val inputTensor = Tensor.fromBlob(floatArray, shape)

                    // DEBUG LOGGING
                    Log.d("PocketPT", "Input Tensor Shape: ${shape.joinToString()}")
                    Log.d("PocketPT", "Input Tensor First 5: ${floatArray.take(5).joinToString()}")
                    var minVal = Float.MAX_VALUE
                    var maxVal = Float.MIN_VALUE
                    for (f in floatArray) {
                        if (f < minVal) minVal = f
                        if (f > maxVal) maxVal = f
                    }
                    Log.d("PocketPT", "Input Tensor Range: [$minVal, $maxVal]")

                    val outputTensor = pytorchModule!!.forward(IValue.from(inputTensor)).toTensor()
                    val outputArray = outputTensor.dataAsFloatArray

                    // DEBUG LOGGING
                    Log.d("PocketPT", "Output Tensor Size: ${outputArray.size}")
                    Log.d("PocketPT", "Output Tensor First 5: ${outputArray.take(5).joinToString()}")

                    val outputList = outputArray.map { it.toDouble() }.toList()
                    result.success(outputList)
                } catch (e: Exception) {
                    result.error("INFERENCE_ERROR", e.message, null)
                }
            }
            "dispose" -> {
                pytorchModule?.destroy()
                pytorchModule = null
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun validateInputTensor(
        floatArray: FloatArray?,
        inputShape: List<Int>?,
        result: MethodChannel.Result
    ): Pair<FloatArray, LongArray>? {
        if (floatArray == null || inputShape == null) {
            result.error("INVALID_ARGUMENT", "input (FloatArray) and inputShape [N,C,H,W] are required", null)
            return null
        }

        if (inputShape.size != 4) {
            result.error("INVALID_ARGUMENT", "inputShape must have 4 entries [N,C,H,W], got $inputShape", null)
            return null
        }

        val expectedSize = inputShape[0] * inputShape[1] * inputShape[2] * inputShape[3]
        if (floatArray.size != expectedSize) {
            result.error(
                "INVALID_ARGUMENT",
                "Input FloatArray length ${floatArray.size} does not match shape product $expectedSize",
                null
            )
            return null
        }

        val shape = longArrayOf(
            inputShape[0].toLong(),
            inputShape[1].toLong(),
            inputShape[2].toLong(),
            inputShape[3].toLong()
        )

        return Pair(floatArray, shape)
    }
}
