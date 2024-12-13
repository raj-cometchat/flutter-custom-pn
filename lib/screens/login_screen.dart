import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_pn/const.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver, CallListener{

  @override
  void initState() {

    super.initState();
    UIKitSettings uiKitSettings = (UIKitSettingsBuilder()
      ..subscriptionType = CometChatSubscriptionType.allUsers
      ..region = AppConstants.region
      ..autoEstablishSocketConnection = true
      ..appId = AppConstants.appId
      ..authKey = AppConstants.authKey
      ..extensions = CometChatUIKitChatExtensions.getDefaultExtensions()
      ..callingExtension = CometChatCallingExtension()
    )
        .build();

    CometChatUIKit.init(
        uiKitSettings: uiKitSettings,
        onSuccess: (String successMessage) async {
          debugPrint("Cometchat ui kit Initialization success");
          final user = await CometChat.getLoggedInUser();
          if (user != null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ));
          }
        },
        onError: (CometChatException e) {
          debugPrint("Initialization failed with exception: ${e.message}");
        });

    debugPrint("CallingExtension enable with context called in login");
    CometChat.addCallListener("CometChatService_CallListener", this);

  }

  void loginUser() {
    setState(() {
      CometChatUIKit.login(AppConstants.loginuser,
          onSuccess: (User user) async {
            debugPrint("Login Successful : $user");
            print("PROCESS -------------------------- 8> Login Successful");
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ));
            /*return CometChatNotifications.registerPushToken(
              PushPlatforms.FCM_FLUTTER_ANDROID,
              providerId: AppConstants.fcmProviderId,
              fcmToken: token,
              onSuccess: (response) {
                debugPrint("registerPushToken:success ${response.toString()}");
                print(
                    "PROCESS -------------------------- 10> Firebase Token Registered");
              },
              onError: (e) {
                debugPrint("registerPushToken:error ${e.toString()}");
                print(
                    "PROCESS -------------------------- 11> Firebase Token NOT Registered");
              },
            );*/
          }, onError: (CometChatException e) {
            debugPrint("Login failed with exception:  ${e.message}");
            print("PROCESS -------------------------- 12> Login NOT Successful");
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("CUSTOM FLUTTER PN APP"),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loginUser,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
