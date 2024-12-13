import 'dart:convert';
import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_apns_x/flutter_apns/src/apns_connector.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_custom_pn/const.dart';
import 'models/call_action.dart';
import 'models/call_type.dart';
import 'models/payload_data.dart';
import 'screens/webview_screen.dart';
import 'shared_perferences.dart';

class APNSService with CometChatCallsEventsListener {
  String? id;

  @override
  void onCallEndButtonPressed() async {
    debugPrint("onCallEndButtonPressed Clicked");
    await FlutterCallkitIncoming.endCall(id!);
  }

  @override
  void onCallEnded() {
    debugPrint("onCallEnded Clicked");
  }

  // This method handles displaying incoming calls, accepting, declining, or ending calls using the FlutterCallkitIncoming and CometChat.
  Future<void> displayIncomingCall(rMessage) async {
    PayloadData payloadData = PayloadData.fromJson(rMessage.data);
    String messageCategory = payloadData.type ?? "";
    if (messageCategory == 'call') {
      CallAction callAction = payloadData.callAction ?? CallAction.none;
      String uuid = payloadData.sessionId ?? "";
      final callUUID = uuid;

      String callerName = payloadData.senderName ?? "";
      CallType callType = payloadData.callType ?? CallType.none;
      if (callAction == CallAction.initiated) {
        CallKitParams callKitParams = CallKitParams(
          id: callUUID,
          nameCaller: callerName,
          appName: 'notification_new',
          type: (callType == CallType.audio) ? 0 : 1,
          textAccept: 'Accept',
          textDecline: 'Decline',
          duration: 55000,
          ios: const IOSParams(
            supportsVideo: true,
            audioSessionMode: 'default',
            audioSessionActive: true,
            audioSessionPreferredSampleRate: 44100.0,
            audioSessionPreferredIOBufferDuration: 0.005,
            ringtonePath: 'system_ringtone_default',
          ),
        );

        await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
      }
    }
  }

  init(BuildContext context) {
    final _connector = ApnsPushConnector();
    _connector.shouldPresent = (x) => Future.value(false);

    _connector.configure(
      // onLaunch gets called, when you tap on notification on a closed app
      onLaunch: (message) async {
        debugPrint('onLaunch: ${message.toString()}');
        openNotification(message, context);
      },

      // onResume gets called, when you tap on notification with app in background
      onResume: (message) async {
        openNotification(message, context);
      },
    );

    //Requesting user permissions
    _connector.requestNotificationPermissions();

    //token value get//
    _connector.token.addListener(() {
      if (_connector.token.value != null || _connector.token.value != '') {
        CometChatNotifications.registerPushToken(
          PushPlatforms.APNS_FLUTTER_DEVICE,
          providerId: AppConstants.apnsProviderId,
          deviceToken: _connector.token.value,
          onSuccess: (response) {
            debugPrint(
                "${_connector.token.value} DEVICE TOKEN - registerPushToken:success ${response.toString()}");
          },
          onError: (e) {
            debugPrint(
                "DEVICE TOKEN - registerPushToken:error ${e.toString()}");
          },
        );
      }
    });

    // Push Token VoIP
    FlutterCallkitIncoming.getDevicePushTokenVoIP().then(
      (voipToken) {
        if (voipToken != null || voipToken.toString().isNotEmpty) {
          debugPrint("$voipToken - VOIP TOKEN ");
          CometChatNotifications.registerPushToken(
            PushPlatforms.APNS_FLUTTER_VOIP,
            providerId: AppConstants.apnsProviderId,
            voipToken: voipToken,
            onSuccess: (response) {
              debugPrint(
                  "VOIP TOKEN - registerPushToken:success ${response.toString()}");
            },
            onError: (e) {
              debugPrint(
                  "VOIP TOKEN - registerPushToken:error ${e.toString()}");
            },
          );
        }
      },
    );

    // Call event listeners

    FlutterCallkitIncoming.onEvent.listen(
      (CallEvent? callEvent) async {
        final Map<String, dynamic> body = callEvent?.body;

        PayloadData payloadData = PayloadData();
        if (body['extra']['message'] != null) {
          payloadData =
              PayloadData.fromJson(jsonDecode(body['extra']['message']));
        }
        String sessionId = payloadData.sessionId ?? '';
        String guid = payloadData.receiver ?? "";
        id = sessionId;

        switch (callEvent?.event) {
          case Event.actionCallIncoming:
 
            SharedPreferencesClass.init();
            break;
          case Event.actionCallAccept:
            SharedPreferencesClass.setString("SessionId", sessionId);
            SharedPreferencesClass.setString("Guid", guid);
            SharedPreferencesClass.setString("callType", callEvent?.body["type"] == 0 ? "audio" : "video");
            OpenWebView(context,guid,sessionId);
            /*UIKitSettings uiKitSettings = (UIKitSettingsBuilder()
                  ..subscriptionType = CometChatSubscriptionType.allUsers
                  ..region = AppConstants.region
                  ..autoEstablishSocketConnection = false
                  ..appId = AppConstants.appId
                  ..authKey = AppConstants.authKey
                  ..extensions =
                      CometChatUIKitChatExtensions.getDefaultExtensions()
                  ..callingExtension = CometChatCallingExtension())
                .build();

            CometChatUIKit.init(
                uiKitSettings: uiKitSettings,
                onSuccess: (String successMessage) async {
                  debugPrint("Cometchat ui kit Initialization success");
                  final user = await CometChat.getLoggedInUser();
                  if (user != null) {
                    CallSettingsBuilder callSettingsBuilder =
                        (CallSettingsBuilder()
                          ..enableDefaultLayout = true
                          ..setAudioOnlyCall =
                              payloadData.callType == CallType.audio);

                    CometChatUIKitCalls.acceptCall(sessionId,
                        onSuccess: (Call call) async {
                      call.category = MessageCategoryConstants.call;
                      CometChatCallEvents.ccCallAccepted(call);
                      await FlutterCallkitIncoming.setCallConnected(sessionId);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CometChatOngoingCall(
                              callSettingsBuilder: callSettingsBuilder,
                              sessionId: sessionId,
                              callWorkFlow: CallWorkFlow.defaultCalling,
                            ),
                          ),
                        ).then((_) async {
                          await const MethodChannel('com.cometchat.flutter_pn')
                              .invokeMethod('endCall');
                        });
                      }
                    }, onError: (CometChatException e) {
                      debugPrint("===>>>: Error: acceptCall: ${e.message}");
                    });
                  }
                },
                onError: (CometChatException e) {
                  debugPrint(
                      "Initialization failed with exception: ${e.message}");
                });*/
            break;

          case Event.actionCallDecline:
            debugPrint("onactionCallDecline Clicked");
            CometChatUIKitCalls.rejectCall(
                sessionId, CallStatusConstants.rejected,
                onSuccess: (Call call) async {
              call.category = MessageCategoryConstants.call;
              CometChatCallEvents.ccCallRejected(call);
              await FlutterCallkitIncoming.endCall(sessionId);
            }, onError: (e) {
              debugPrint(
                  "Unable to end call from incoming call screen ${e.message}");
            });
            break;
          case Event.actionCallEnded:
            debugPrint("onactionCallEnded Clicked");
            CometChat.endCall(
              sessionId,
              onSuccess: (call) {
                CometChat.clearActiveCall();
                CometChatCalls.endSession(
                  onSuccess: (onSuccess) {
                    CometChatCallEvents.ccCallEnded(call);
                    debugPrint("END CALl");
                  },
                  onError: (excep) {
                    debugPrint("CALl NOT ENDED $excep");
                  },
                );
              },
              onError: (excep) {
                debugPrint("$excep");
              },
            );
            /*CometChatUIKitCalls.endSession(
              onSuccess: (message) {
                CometChat.clearActiveCall();
                //Navigator.pop(context);
              },
              onError: (error) {
                  debugPrint(
                      'caught in endSession call could not be ended: ${error.message}');
              },
            );*/

            break;
          default:
            break;
        }
      },
      cancelOnError: false,
      onDone: () {
        debugPrint('FlutterCallkitIncoming.onEvent: done');
      },
      onError: (e) {
        debugPrint('FlutterCallkitIncoming.onEvent:error ${e.toString()}');
      },
    );
  }

  // This method processes the incoming Remote message to handle user or group notifications and carries out appropriate actions such as initiating a chat or call.

  Future<void> openNotification(RemoteMessage? message, BuildContext context) async {
    if (message != null) {
      PayloadData payloadData = PayloadData.fromJson(message.data);
      if (payloadData.type == "call") {
        displayIncomingCall(message);
      } else {
        final receiverType = payloadData.receiverType ?? "";
        User? sendUser;
        Group? sendGroup;

        String messageCategory = payloadData.type ?? "";

        if (receiverType == CometChatReceiverType.user) {
          final uid = payloadData.sender ?? "";
          await CometChat.getUser(
            uid,
            onSuccess: (user) {
              debugPrint("Got User App Background $user");
              sendUser = user;
            },
            onError: (excep) {
              debugPrint(excep.message);
            },
          );
        } else if (receiverType == CometChatReceiverType.group) {
          final guid = payloadData.receiver ?? "";
          await CometChat.getGroup(
            guid,
            onSuccess: (group) {
              sendGroup = group;
            },
            onError: (excep) {
              debugPrint(excep.message);
            },
          );
        }

        if (messageCategory == "chat" &&
                (receiverType == CometChatReceiverType.user &&
                    sendUser != null) ||
            (receiverType == CometChatReceiverType.group &&
                sendGroup != null)) {
          if (context.mounted) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CometChatMessages(
                    user: sendUser,
                    group: sendGroup,
                  ),
                ),
              );
            });
          }
        }
      }
    }
  }
}

void OpenWebView(BuildContext context, String guid, sessionID) {
  // String authToken = CometChat.getUserAuthToken().toString();
  print("PROCESS 2 ------------------------------> 410");
  String authToken = "superhero4_173340169895f3eafd536ca6da3864fbd9f26ef2";
  print("AUTH TOKEN - $authToken");
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WebViewPage(authToken, guid, sessionID),
    ),
  );
}