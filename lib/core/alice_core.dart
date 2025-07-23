import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_alice/core/debug_pop_up.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_http_error.dart';
import 'package:flutter_alice/model/alice_http_response.dart';
import 'package:flutter_alice/ui/page/alice_calls_list_screen.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:rxdart/rxdart.dart';

class AliceCore {
  factory AliceCore({
    required GlobalKey<NavigatorState>? navigatorKey,
    required String notificationIcon,
    required bool showNotification,
    required bool showInspectorOnShake,
    required bool darkTheme,
  }) {
    _singleton ??= AliceCore._(
      navigatorKey,
      showNotification,
      showInspectorOnShake,
      darkTheme,
      notificationIcon,
    );

    return _singleton!;
  }

  /// Creates alice core instance
  AliceCore._(
    this._navigatorKey,
    this.showNotification,
    this.showInspectorOnShake,
    this.darkTheme,
    this.notificationIcon,
  ) {
    if (showNotification) {
      _callsSubscription = callsSubject.listen((_) => _onCallsChanged());
    }
    _brightness = darkTheme ? Brightness.dark : Brightness.light;
  }

  /// Should user be notified with notification if there's new request catched
  /// by Alice
  final bool showNotification;

  /// Should inspector be opened on device shake (works only with physical
  /// with sensors)
  final bool showInspectorOnShake;

  /// Should inspector use dark theme
  final bool darkTheme;

  /// Rx subject which contains all intercepted http calls
  final BehaviorSubject<List<AliceHttpCall>> callsSubject =
      BehaviorSubject<List<AliceHttpCall>>.seeded(<AliceHttpCall>[]);

  /// Icon url for notification
  final String notificationIcon;

  GlobalKey<NavigatorState>? _navigatorKey;
  Brightness _brightness = Brightness.light;
  bool _isInspectorOpened = false;
  StreamSubscription<List<AliceHttpCall>>? _callsSubscription;
  String? _notificationMessage;
  String? _notificationMessageShown;
  bool _notificationProcessing = false;

  static AliceCore? _singleton;

  /// Dispose subjects and subscriptions
  void dispose() {
    callsSubject.close();
    //_shakeDetector?.stopListening();
    _callsSubscription?.cancel();
  }

  /// Get currently used brightness
  Brightness get brightness => _brightness;

  Future<void> _onCallsChanged() async {
    if (callsSubject.value.isNotEmpty) {
      _notificationMessage = _getNotificationMessage();
      if (_notificationMessage != _notificationMessageShown && !_notificationProcessing) {
        await _showLocalNotification();
        await _onCallsChanged();
      }
    }
  }

  /// Set custom navigation key. This will help if there's route library.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void navigateToCallListScreen() {
    final BuildContext? context = getContext();
    if (context == null) {
      // print('Cant start Alice HTTP Inspector. Please add NavigatorKey to your application');
      return;
    }
    if (!_isInspectorOpened) {
      _isInspectorOpened = true;
      Navigator.push(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => AliceCallsListScreen(this),
        ),
      ).then((dynamic onValue) => _isInspectorOpened = false);
    }
  }

  /// Get context from navigator key. Used to open inspector route.
  BuildContext? getContext() => _navigatorKey?.currentState?.overlay?.context;

  String _getNotificationMessage() {
    final List<AliceHttpCall>? calls = callsSubject.valueOrNull;

    if (calls == null) {
      return 'Error';
    }

    final int successCalls = calls
        .where(
          (AliceHttpCall call) =>
              call.response != null && (call.response?.status ?? 0) >= 200 && (call.response?.status ?? 0) < 300,
        )
        .toList()
        .length;

    final int redirectCalls = calls
        .where(
          (AliceHttpCall call) =>
              call.response != null && (call.response?.status ?? 0) >= 300 && (call.response?.status ?? 0) < 400,
        )
        .toList()
        .length;

    final int errorCalls = calls
        .where(
          (AliceHttpCall call) =>
              call.response != null && (call.response?.status ?? 0) >= 400 && (call.response?.status ?? 0) < 600,
        )
        .toList()
        .length;

    final int loadingCalls = calls.where((AliceHttpCall call) => call.loading).toList().length;

    final StringBuffer notificationsMessage = StringBuffer();
    if (loadingCalls > 0) {
      notificationsMessage.write('Loading: $loadingCalls');
      notificationsMessage.write(' | ');
    }
    if (successCalls > 0) {
      notificationsMessage.write('Success: $successCalls');
      notificationsMessage.write(' | ');
    }
    if (redirectCalls > 0) {
      notificationsMessage.write('Redirect: $redirectCalls');
      notificationsMessage.write(' | ');
    }
    if (errorCalls > 0) {
      notificationsMessage.write('Error: $errorCalls');
    }
    return notificationsMessage.toString();
  }

  Future<void> _showLocalNotification() async {
    _notificationProcessing = true;
    final String? message = _notificationMessage;

    showDebugAnimNotification();
    _notificationMessageShown = message;
    _notificationProcessing = false;
  }

  /// Add alice http call to calls subject
  void addRequest(AliceHttpCall call) {
    // print('++++++ alice addRequest: ${call.uri} ${call.id}');
    final AliceHttpCall? selectedCall = _selectCall(call.id);

    // in case if some of interceptors added call with the same id
    if (selectedCall != null) {
      return;
    }

    callsSubject.add(<AliceHttpCall>[
      call,
      ...callsSubject.value,
    ]);
  }

  /// Add error to exisng alice http call
  void addError(AliceHttpError error, int requestId) {
    final AliceHttpCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      // print('Selected call is null');
      return;
    }

    selectedCall.error = error;
    callsSubject.add(<AliceHttpCall>[
      // selectedCall,
      ...callsSubject.value,
    ]);
  }

  /// Add response to existing alice http call
  void addResponse(AliceHttpResponse response, int requestId) {
    final AliceHttpCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      // print('Selected call is null');
      return;
    }
    selectedCall.loading = false;
    selectedCall.response = response;
    selectedCall.duration = response.time.millisecondsSinceEpoch - selectedCall.request!.time.millisecondsSinceEpoch;

    callsSubject.add(<AliceHttpCall>[
      // selectedCall,
      ...callsSubject.value,
    ]);
  }

  /// Add alice http call to calls subject
  void addHttpCall(AliceHttpCall aliceHttpCall) {
    assert(aliceHttpCall.request != null, "Http call request can't be null");
    assert(aliceHttpCall.response != null, "Http call response can't be null");
    callsSubject.add(<AliceHttpCall>[
      aliceHttpCall,
      ...callsSubject.value,
    ]);
  }

  /// Remove all calls from calls subject
  void removeCalls() {
    callsSubject.add(<AliceHttpCall>[]);
  }

  AliceHttpCall? _selectCall(int requestId) {
    // log('callsSubject.value: ${callsSubject.value.map((AliceHttpCall call) => call.id).toList()} requestId: $requestId');

    return callsSubject.value.firstWhereOrNull((AliceHttpCall call) {
      return call.id == requestId;
    });
  }

  bool isShowedBubble = false;

  void showDebugAnimNotification() {
    if (isShowedBubble) {
      return;
    }
    final BuildContext? context = getContext();
    if (context == null) {
      return;
    }
    isShowedBubble = true;
    showOverlay(
      (BuildContext context, double t) {
        return Opacity(
          opacity: t,
          child: DebugPopUp(
            callsSubscription: callsSubject.stream,
            onClicked: navigateToCallListScreen,
            aliceCore: this,
          ),
        );
      },
      duration: Duration.zero,
    );
  }
}
