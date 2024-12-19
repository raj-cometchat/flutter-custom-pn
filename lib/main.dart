import 'dart:async';

import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_pn/screens/login_screen.dart';
import 'package:flutter_custom_pn/sufin.dart';
import 'package:get/get.dart';

import 'shared_perferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initServices();
    super.initState();
  }

  initServices() async {
    SharedPreferencesClass.init();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'Push Notifications Sample App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(),
        home: LoginScreen(
          key: CallNavigationContext.navigatorKey,
        )
        //home: SplashScreen()
        );
  }
}

// // SplashScreen with 4 seconds delay
// class SplashScreen extends StatefulWidget {
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _navigateToMainScreen();
//   }
//
//   // Navigate to MainScreen after a 4-second delay
//   void _navigateToMainScreen() {
//     Timer(Duration(seconds: 4), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//             builder: (context) =>
//                 MainScreen(key: CallNavigationContext.navigatorKey)),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue, // Splash screen background color
//       body: Center(
//         child: Text(
//           'Splash Screen', // You can customize this with your app logo or name
//           style: TextStyle(
//             fontSize: 24,
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
