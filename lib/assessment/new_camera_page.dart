// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:tflite/tflite.dart';
// // import 'package:tflite_flutter/tflite_flutter.dart';
// // import 'package:tflite_flutter/tflite_flutter_platform_interface.dart';

// List<CameraDescription>? cameras;

// class MainCameraPage extends StatefulWidget {
//   const MainCameraPage({super.key});

//   @override
//   State<MainCameraPage> createState() => _MainCameraPageState();
// }

// class _MainCameraPageState extends State<MainCameraPage> {
//   CameraImage? cameraImage;
//   CameraController? cameraController;
//   String output = '';

//   @override
//   void initState() {
//     super.initState();
//     loadCamera();
//     loadModel();
//   }

//   Future<void> loadCamera() async {
//     cameraController = CameraController(cameras![0], ResolutionPreset.medium);
//     await cameraController!.initialize();
    
//     if (!mounted) return;

//     cameraController!.startImageStream((imageStream) {
//       cameraImage = imageStream;
//       runModel();
//     });

//     setState(() {});
//   }

//   Future<void> runModel() async {
//     if (cameraImage != null) {
//       var predictions = await Tflite.runModelOnFrame(
//         bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
//         imageHeight: cameraImage!.height,
//         imageWidth: cameraImage!.width,
//         imageMean: 127.5,
//         imageStd: 127.5,
//         numResults: 2,
//         threshold: 0.1,
//         asynch: true,
//       );

//       if (predictions != null && predictions.isNotEmpty) {
//         setState(() {
//           output = predictions.first['label'] ?? '';
//         });
//       }
//     }
//   }

//   Future<void> loadModel() async {
//     await Tflite.loadModel(
//       model: "assets/model/pain_model.tflite",
//       labels: "assets/model/pain_labels.txt",
//     );
//   }

//   @override
//   void dispose() {
//     cameraController?.dispose();
//     Tflite.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Camera')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: SizedBox(
//               height: MediaQuery.of(context).size.height * 0.7,
//               width: MediaQuery.of(context).size.width,
//               child: (cameraController != null &&
//                       cameraController!.value.isInitialized)
//                   ? AspectRatio(
//                       aspectRatio: cameraController!.value.aspectRatio,
//                       child: CameraPreview(cameraController!),
//                     )
//                   : const Center(child: CircularProgressIndicator()),
//             ),
//           ),
//           Text(
//             output,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }