import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_pn/screens/login_screen.dart';
import 'package:get/get.dart';

import 'shared_perferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Text('Flutter Demo Home Page'),
    );
  }

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
    return MaterialApp(
      title: 'Push Notifications Sample App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: LoginScreen(
        key: CallNavigationContext.navigatorKey,
      ),
    );
  }
}
