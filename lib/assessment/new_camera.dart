// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'new_camera_page.dart';

// List<CameraDescription>? cameras;

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
//   runApp(MyCamera());
// }

// class MyCamera extends StatelessWidget {
//   const MyCamera({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(primaryColor: Colors.blueGrey),
//       debugShowCheckedModeBanner: false,
//       home: const MainCameraPage(),
//     );
//   }
// }