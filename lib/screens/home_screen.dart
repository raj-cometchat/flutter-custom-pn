import 'dart:io';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_pn/shared_perferences.dart';
import '../apns_service.dart';
import '../firebase_service.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseService notificationService = FirebaseService();
  final APNSService apnsServices = APNSService();
  HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, CallListener {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    if (Platform.isAndroid) {
    widget.notificationService.init(context);
    } else {
      widget.apnsServices.init(context);
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (Platform.isAndroid) {
      widget.notificationService.resumeCallListeners(context);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CometChatConversationsWithMessages(
      conversationsConfiguration: ConversationsConfiguration(
        showBackButton: false,
        appBarOptions: [
          InkWell(
            child: const Icon(Icons.logout, color: Color(0xFF6851D6)),
            onTap: () async {
              debugPrint("Logout Successful");
              CometChatNotifications.unregisterPushToken(onSuccess: (response) {
                SharedPreferencesClass.clear();
                debugPrint(
                    "unregisterPushToken:success ${response.toString()}");
              }, onError: (e) {
                debugPrint("unregisterPushToken:error ${e.toString()}");
              });
              await CometChatUIKit.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(width: 10)
        ],
      ),
    ));
  }
}
