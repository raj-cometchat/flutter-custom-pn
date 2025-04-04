import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage(this.authToken, this.guid, this.sessionId);

  final String authToken;
  final String guid;
  final String sessionId;

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  // Define the webViewController as nullable
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
    } else if (state == AppLifecycleState.paused) {}
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
                  // // url: WebUri("https://cometchat.com")),
                  // url: WebUri(
                  //     "https://webview-sufin-test.netlify.app/?guid=${widget.guid}&sessionId=${widget.sessionId}&authToken=${widget.authToken}")),
                  url: WebUri(
                      "https://webview-sufin-test.netlify.app/?guid=${widget.guid}&sessionId=${widget.sessionId}&authToken=${widget.authToken}")),
              initialSettings: InAppWebViewSettings(
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                isInspectable: true,
                javaScriptEnabled: true, // Enable JavaScript
              ),
              onWebViewCreated: (InAppWebViewController controller) {
                // Initialize the webViewController when the WebView is created
                webViewController = controller;
                webViewController?.addJavaScriptHandler(
                  handlerName: 'messageFromJS',
                  callback: (args) async {
                      FlutterCallkitIncoming.endCall(widget.sessionId);
                      print("Received from JS: $args");
                      // Handle received data here (e.g., update UI, save to shared preferences)
                  },
                );
                // webViewController?.addJavaScriptHandler(
                //   handlerName: 'callJoiningMessage',
                //   callback: (args) async {
                //     //if (widget.lock) {
                //     Timer(Duration(seconds: 3), () {
                //       print("Executed after 3 seconds");
                //       FlutterCallkitIncoming.endCall(widget.sessionId);
                //     });
                //     print("Received from JS: $args");
                //     // Handle received data here (e.g., update UI, save to shared preferences)
                //     // }
                //   },
                // );
              },
              androidOnPermissionRequest:
                  (controller, origin, resources) async {
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
      ),
    );
  }
}
