import 'dart:io';

import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  InAppWebViewController? webViewController;

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
    PlatformInAppWebViewController.debugLoggingSettings.enabled = true;
    return Scaffold(
        body: Column(
      children: [
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(
                url: WebUri(
                    "https://webview-sufin-test.netlify.app/")),
            initialSettings: InAppWebViewSettings(isInspectable: true,
              javaScriptEnabled: true, // Enable JavaScript
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              // Initialize the webViewController when the WebView is created
              webViewController = controller;
            },
            androidOnPermissionRequest: (controller, origin, resources) async {
              // Automatically grant permission for camera and microphone
              return PermissionRequestResponse(
                  resources: resources,
                  action: PermissionRequestResponseAction.GRANT);
            },
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT);
            },
            /* onLoadStart: (InAppWebViewController controller, WebUri? url) {
    print("Started loading: $url");
    },
    onLoadStop:
    (InAppWebViewController controller, WebUri? url) async {
    print("Finished loading: $url");
    },
    onProgressChanged:
    (InAppWebViewController controller, int progress) {
    print("Loading progress: $progress%");
    },*/
          ),
        ),
      ],
    ));
  }
}
