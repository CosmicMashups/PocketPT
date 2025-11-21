import Flutter
import UIKit
import onnxruntime_objc

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var poseSession: ORTSession?
  private var painSession: ORTSession?
  private var ortEnv: ORTEnv?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Pose estimation model channel
    let poseChannel = FlutterMethodChannel(
      name: "com.pocketpt/onnxruntime",
      binaryMessenger: controller.binaryMessenger
    )
    
    // Pain detection model channel
    let painChannel = FlutterMethodChannel(
      name: "com.pocketpt/onnxruntime-pain",
      binaryMessenger: controller.binaryMessenger
    )
    
    ortEnv = try? ORTEnv(loggingLevel: .warning)
    
    // Pose channel handler
    poseChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleOnnxMethodCall(call: call, result: result, session: self?.poseSession, setSession: { self?.poseSession = $0 }, inputName: "images", outputName: "output0")
    }
    
    // Pain channel handler
    painChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleOnnxMethodCall(call: call, result: result, session: self?.painSession, setSession: { self?.painSession = $0 }, inputName: "input", outputName: "output")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleOnnxMethodCall(
    call: FlutterMethodCall,
    result: @escaping FlutterResult,
    session: ORTSession?,
    setSession: ((ORTSession?) -> Void)?,
    inputName: String,
    outputName: String
  ) {
    switch call.method {
    case "initialize":
      do {
        guard let args = call.arguments as? [String: Any],
              let modelPath = args["modelPath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "modelPath is required", details: nil))
          return
        }
        
        let sessionOptions = try ORTSessionOptions()
        let newSession = try ORTSession(env: self.ortEnv!, modelPath: modelPath, sessionOptions: sessionOptions)
        setSession?(newSession)
        result(true)
      } catch {
        result(FlutterError(code: "INIT_ERROR", message: error.localizedDescription, details: nil))
      }
      
    case "run":
      do {
        guard let currentSession = session else {
          result(FlutterError(code: "NOT_INITIALIZED", message: "Session not initialized", details: nil))
          return
        }
        
        guard let args = call.arguments as? [String: Any],
              let inputList = args["input"] as? [Double],
              let inputShape = args["inputShape"] as? [Int] else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "input and inputShape are required", details: nil))
          return
        }
        
        // Convert [Double] to [Float]
        let floatArray = inputList.map { Float($0) }
        
        // Create input tensor
        let shape: [NSNumber] = inputShape.map { NSNumber(value: $0) }
        let inputData = NSMutableData(bytes: floatArray, length: floatArray.count * MemoryLayout<Float>.size)
        let inputTensor = try ORTValue(tensorData: inputData,
                                      elementType: .float,
                                      shape: shape)
        
        // Run inference
        let inputs = [inputName: inputTensor]
        let outputs = try currentSession.run(withInputs: inputs, outputNames: [outputName], runOptions: nil)
        
        // Get output tensor
        guard let outputTensor = outputs[outputName] else {
          result(FlutterError(code: "OUTPUT_ERROR", message: "Output tensor not found", details: nil))
          return
        }
        
        let outputData = try outputTensor.tensorData() as Data
        let outputArray = outputData.withUnsafeBytes { 
          Array(UnsafeBufferPointer<Float>(start: $0.baseAddress?.assumingMemoryBound(to: Float.self), 
                                           count: outputData.count / MemoryLayout<Float>.size)) 
        }
        
        // Convert to [Double]
        let outputList = outputArray.map { Double($0) }
        
        result(outputList)
      } catch {
        result(FlutterError(code: "INFERENCE_ERROR", message: error.localizedDescription, details: nil))
      }
      
    case "dispose":
      setSession?(nil)
      result(nil)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
