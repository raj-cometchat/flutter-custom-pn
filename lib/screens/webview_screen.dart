import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage(this.guid, this.sessionId, {super.key});

  final String guid;
  final String sessionId;

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  // Define the webViewController as nullable
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                  // url: WebUri("https://cometchat.com")),
                  url: WebUri(
                      "https://webview-sufin-test.netlify.app/?guid=${widget.guid}&sessionId=${widget.sessionId}&authToken=superhero4_173340169895f3eafd536ca6da3864fbd9f26ef2")),
              // url: WebUri("https://sufin-notification-test-calling.netlify.app/")),
              //url: WebUri("https://sufin-notification-test-calling.netlify.app/?guid=${widget.guid}&sessionId=${widget.sessionId}&authToken=${widget.authToken}")),
              //url: WebUri("https://angular-v15-v4.netlify.app/")),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true, // Enable JavaScript
              ),
              onWebViewCreated: (InAppWebViewController controller) {
                // Initialize the webViewController when the WebView is created
                webViewController = controller;
              }/*,androidOnPermissionRequest:
                (controller, origin, resources) async {
              // Automatically grant permission for camera and microphone
              return PermissionRequestResponse(
                  resources: resources,
                  action: PermissionRequestResponseAction.GRANT);
            }*/,onPermissionRequest: (controller, request) async {
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
