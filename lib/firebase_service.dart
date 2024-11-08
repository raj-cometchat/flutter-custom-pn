import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_custom_pn/const.dart';
import 'package:flutter_custom_pn/models/payload_data.dart';
import 'package:flutter_custom_pn/shared_perferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';
import 'models/call_action.dart';
import 'models/call_type.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage rMessage) async {
  await displayIncomingCall(rMessage);
}

String? activeCallSession;

Future<void> displayIncomingCall(RemoteMessage rMessage) async {
  Map<String, dynamic> ccMessage = rMessage.data;

  PayloadData callPayload = PayloadData.fromJson(ccMessage);

  String messageCategory = callPayload.type ?? "";

  if (messageCategory == 'call') {
    CallAction callAction = callPayload.callAction!;
    String uuid = callPayload.sessionId ?? "";
    final callUUID = uuid;
    String callerName = callPayload.senderName ?? "";
    CallType callType = callPayload.callType ?? CallType.none;
    if (callAction == CallAction.initiated &&
        (callPayload.sentAt != null &&
            DateTime.now().isBefore(
                callPayload.sentAt!.add(const Duration(seconds: 40))))) {
      CallKitParams callKitParams = CallKitParams(
        id: callUUID,
        nameCaller: callerName,
        appName: 'notification_new',
        type: (callType == CallType.audio) ? 0 : 1,
        textAccept: 'Accept',
        textDecline: 'Decline',
        duration: 40000,
        android: const AndroidParams(
            isCustomNotification: true,
            isShowLogo: false,
            backgroundColor: '#0955fa',
            actionColor: '#4CAF50',
            incomingCallNotificationChannelName: "Incoming Call",
            isShowFullLockedScreen: false),
      );
      await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);

      FlutterCallkitIncoming.onEvent.listen(
        (CallEvent? callEvent) async {
          switch (callEvent?.event) {
            case Event.actionCallIncoming:
              SharedPreferencesClass.init();
              break;
            case Event.actionCallAccept:
              SharedPreferencesClass.setString(
                  "SessionId", callEvent?.body["id"]);
              SharedPreferencesClass.setString(
                  "callType", callEvent?.body["type"] == 0 ? "audio" : "video");
              break;
            case Event.actionCallDecline:
              UIKitSettings uiKitSettings = (UIKitSettingsBuilder()
                    ..subscriptionType = CometChatSubscriptionType.allUsers
                    ..region = AppConstants.region
                    ..autoEstablishSocketConnection = true
                    ..appId = AppConstants.appId
                    ..authKey = AppConstants.authKey
                    ..extensions =
                        CometChatUIKitChatExtensions.getDefaultExtensions()
                    ..callingExtension = CometChatCallingExtension())
                  .build();

              CometChatUIKit.init(
                  uiKitSettings: uiKitSettings,
                  onSuccess: (String successMessage) {
                    debugPrint("Cometchat ui kit Initialization success");
                  },
                  onError: (CometChatException e) {
                    debugPrint(
                        "Initialization failed with exception: ${e.message}");
                  });
              debugPrint(
                  "CallingExtension enable with context called in login");

              //CometChat.addCallListener("CometChatService_CallListener", this);

              CometChatUIKitCalls.rejectCall(
                  callEvent?.body["id"], CallStatusConstants.rejected,
                  onSuccess: (Call call) async {
                call.category = MessageCategoryConstants.call;
                CometChatCallEvents.ccCallRejected(call);
                await FlutterCallkitIncoming.endCall(callEvent?.body['id']);
                if (kDebugMode) {
                  debugPrint('incoming call was rejected');
                }
              }, onError: (e) {
                if (kDebugMode) {
                  debugPrint(
                      "Unable to end call from incoming call screen ${e.message}");
                }
              });

              break;
            case Event.actionCallEnded:
              await FlutterCallkitIncoming.endCall(callEvent?.body['id']);
              break;
            default:
              break;
          }
        },
        cancelOnError: false,
        onDone: () {
          if (kDebugMode) {
            debugPrint('FlutterCallkitIncoming.onEvent: done');
          }
        },
        onError: (e) {
          if (kDebugMode) {
            debugPrint('FlutterCallkitIncoming.onEvent:error ${e.toString()}');
          }
        },
      );
    } else if (callAction == CallAction.cancelled ||
        callAction == CallAction.unanswered) {
      if (callPayload.sessionId != null) {
        await FlutterCallkitIncoming.endCall(callPayload.sessionId ?? "");
        activeCallSession = null;
      }
    }
  }
}

class FirebaseService with WidgetsBindingObserver, CallListener {
  // 1. Declare Firebase Messaging
  late final FirebaseMessaging _firebaseMessaging;
  late final NotificationSettings _settings;
  late var cameraStatus, microphoneStatus;

  Future<void> init(BuildContext context) async {
    try {
      // 2. Initialize the Firebase
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      // 3. Get FirebaseMessaging instance
      _firebaseMessaging = FirebaseMessaging.instance;

      // 4. Request permissions
      await requestPermissions();

      // 5. Setup notification listeners
      if (context.mounted) await initListeners(context);

      // 6. Fetch and register FCM token
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        CometChatNotifications.registerPushToken(
          PushPlatforms.FCM_FLUTTER_ANDROID,
          providerId: AppConstants.fcmProviderId,
          fcmToken: token,
          // deviceToken: !isFcm && !isVoip ? token : null,
          // voipToken: !isFcm && isVoip ? token : null,
          onSuccess: (response) {
            debugPrint("registerPushToken:success ${response.toString()}");
          },
          onError: (e) {
            debugPrint("registerPushToken:error ${e.toString()}");
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase initialization error: $e');
      }
    }
  }

  // method for requesting notification permission
  Future<void> requestPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
      cameraStatus = await Permission.camera.request();
      microphoneStatus = await Permission.microphone.request();

      _settings = settings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting permissions: $e');
      }
    }
  }

  // This method initializes Firebase message listeners to handle background notifications, token refresh, and user interactions with messages, after checking for user permission authorization.

  Future<void> initListeners(BuildContext context) async {
    try {
      if (_settings.authorizationStatus == AuthorizationStatus.authorized && cameraStatus == AuthorizationStatus.authorized && microphoneStatus==AuthorizationStatus.authorized) {
        if (kDebugMode) {
          debugPrint('User granted permission');
        }

        // For handling notification when the app is in the background
        FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler);

        // refresh token listener
        _firebaseMessaging.onTokenRefresh.listen((String token) async {
          if (kDebugMode) {
            debugPrint('Token refreshed: $token');
          }
          CometChatNotifications.registerPushToken(
            PushPlatforms.FCM_FLUTTER_ANDROID,
            providerId: AppConstants.fcmProviderId,
            fcmToken: token,
            // deviceToken: !isFcm && !isVoip ? token : null,
            // voipToken: !isFcm && isVoip ? token : null,
            onSuccess: (response) {
              debugPrint("registerPushToken:success ${response.toString()}");
            },
            onError: (e) {
              debugPrint("registerPushToken:error ${e.toString()}");
            },
          );
        });

        // This line sets up a listener that triggers the 'openNotification' method when a user taps on a notification and the app opens.

        // Handling a notification click event when the app is in the background
        FirebaseMessaging.onMessageOpenedApp
            .listen((RemoteMessage message) async {
          openNotification(context, message);
        });

        // Handling the initial message received when the app is launched from dead (killed state)
        // When the app is killed and a new notification arrives when user clicks on it
        // It gets the data to which screen to open
        FirebaseMessaging.instance
            .getInitialMessage()
            .then((RemoteMessage? message) async {
          if (message != null) {
            openNotification(context, message);
          }
        });
        openFromTerminatedState(context);
      } else {
        if (kDebugMode) {
          debugPrint('User declined or has not accepted permission');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing listeners: $e.');
      }
    }
  }

  // This method processes the incoming Firebase message to handle user or group notifications and carries out appropriate actions such as initiating a chat or call.

  Future<void> openNotification(BuildContext context, RemoteMessage? message) async {
    if (message != null) {
      Map<String, dynamic> data = message.data;

      PayloadData payload = PayloadData.fromJson(data);
      String messageCategory = payload.type ?? "";

      final receiverType = payload.receiverType ?? "";
      User? sendUser;
      Group? sendGroup;

      if (receiverType == "user") {
        final uid = payload.sender ?? '';

        await CometChat.getUser(
          uid,
          onSuccess: (user) {
            debugPrint("User fetched $user");
            sendUser = user;
          },
          onError: (exception) {
            if (kDebugMode) {
              debugPrint("Error while retrieving user ${exception.message}");
            }
          },
        );
      } else if (receiverType == "group") {
        final guid = payload.receiver ?? '';

        await CometChat.getGroup(
          guid,
          onSuccess: (group) {
            sendGroup = group;
          },
          onError: (exception) {
            if (kDebugMode) {
              debugPrint("Error while retrieving group ${exception.message}");
            }
          },
        );
      }

      if (messageCategory == "call") {
        CallAction callAction = payload.callAction!;
        String uuid = payload.sessionId ?? "";

        if (callAction == CallAction.initiated) {
          if (receiverType == ReceiverTypeConstants.user && sendUser != null) {
            Call call = Call(
                sessionId: uuid,
                receiverUid: sendUser?.uid ?? "",
                type: payload.callType?.value ?? "",
                receiverType: receiverType);

            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CometChatIncomingCall(
                    call: call,
                    user: sendUser,
                  ),
                ),
              );
            }
          }
        } else if (receiverType == ReceiverTypeConstants.group &&
            sendGroup != null) {
          if (kDebugMode) {
            debugPrint("we are in group call");
          }
        } else if (callAction == CallAction.cancelled) {
          if (activeCallSession != null) {
            await FlutterCallkitIncoming.endCall(activeCallSession!);
            activeCallSession = null;
          }
        }
      }

      // Navigating to the chat screen when messageCategory is message
      if (messageCategory == "chat" &&
              (receiverType == ReceiverTypeConstants.user &&
                  sendUser != null) ||
          (receiverType == ReceiverTypeConstants.group && sendGroup != null)) {
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

  String? activeCallSession;

  // Deletes fcm token

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while deleting token $e');
      }
    }
  }

  // checks For navigation when app opens from terminated state when we accept call
  openFromTerminatedState(context) {
    final sessionID = SharedPreferencesClass.getString("SessionId");
    final callType = SharedPreferencesClass.getString("callType");

    if (sessionID.isNotEmpty) {
      CallSettingsBuilder callSettingsBuilder = (CallSettingsBuilder()
        ..enableDefaultLayout = true
        ..setAudioOnlyCall = (callType == "audio"));
      CometChatUIKitCalls.acceptCall(sessionID, onSuccess: (Call call) {
        call.category = MessageCategoryConstants.call;
        CometChatCallEvents.ccCallAccepted(call);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CometChatOngoingCall(
              callSettingsBuilder: callSettingsBuilder,
              sessionId: sessionID,
              callWorkFlow: CallWorkFlow.defaultCalling,
            ),
          ),
        );
      }, onError: (e) {
        debugPrint(
            "Unable to accept call from incoming call screen ${e.details}");
      });
    }
  }

  // checks For navigation when app opens from background state when we accept call
  resumeCallListeners(BuildContext context) async {
    FlutterCallkitIncoming.onEvent.listen(
      (CallEvent? callEvent) async {
        switch (callEvent?.event) {
          case Event.actionCallIncoming:
            CometChatUIKitCalls.init(AppConstants.appId, AppConstants.region,
                onSuccess: (p0) {
              debugPrint("CometChatUIKitCalls initialized successfully");
            }, onError: (e) {
              debugPrint("CometChatUIKitCalls failed ${e.message}");
            });
            activeCallSession = callEvent?.body["id"];
            break;
          case Event.actionCallAccept:
            final callType = callEvent?.body["type"];
            CallSettingsBuilder callSettingsBuilder = (CallSettingsBuilder()
              ..enableDefaultLayout = true
              ..setAudioOnlyCall = (callType == "audio"));

            CometChatUIKitCalls.acceptCall(callEvent!.body["id"],
                onSuccess: (Call call) {
              call.category = MessageCategoryConstants.call;
              CometChatCallEvents.ccCallAccepted(call);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CometChatOngoingCall(
                    callSettingsBuilder: callSettingsBuilder,
                    sessionId: callEvent.body["id"],
                  ),
                ),
              );
            }, onError: (e) {
              debugPrint(
                  "Unable to accept call from incoming call screen ${e.message}");
            });
            break;
          case Event.actionCallDecline:
            CometChatUIKitCalls.rejectCall(
                callEvent?.body["id"], CallStatusConstants.rejected,
                onSuccess: (Call call) {
              call.category = MessageCategoryConstants.call;
              CometChatCallEvents.ccCallRejected(call);
              debugPrint('incoming call was cancelled');
            }, onError: (e) {
              debugPrint(
                  "Unable to end call from incoming call screen ${e.message}");
              debugPrint(
                  "Unable to end call from incoming call screen ${e.details}");
            });
            break;
          case Event.actionCallEnded:
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
}
