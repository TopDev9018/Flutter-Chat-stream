import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:stream_chat_flutter_core/src/typedef.dart';

/// Widget used to provide information about the chat to the widget tree.
/// This Widget is used to react to life cycle changes and system updates.
/// When the app goes into the background, the websocket connection is kept
/// alive for two minutes before being terminated.
///
/// Conversely, when app is resumed or restarted, a new connection is initiated.
///
/// ```dart
/// class MyApp extends StatelessWidget {
///   final StreamChatClient client;
///
///   MyApp(this.client);
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Container(
///         child: StreamChatCore(
///           client: client,
///           child: ChannelListPage(),
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
class StreamChatCore extends StatefulWidget {
  /// Constructor used for creating a new instance of [StreamChatCore].
  ///
  /// [StreamChatCore] is a stateful widget which reacts to system events and
  /// updates Stream's connection status accordingly.
  const StreamChatCore({
    Key? key,
    required this.client,
    required this.child,
    this.onBackgroundEventReceived,
    this.backgroundKeepAlive = const Duration(minutes: 1),
    this.connectivityStream,
  }) : super(key: key);

  /// Instance of Stream Chat Client containing information about the current
  /// application.
  final StreamChatClient client;

  /// Widget descendant.
  final Widget child;

  /// The amount of time that will pass before disconnecting the client in
  /// the background
  final Duration backgroundKeepAlive;

  /// Handler called whenever the [client] receives a new [Event] while the app
  /// is in background. Can be used to display various notifications depending
  /// upon the [Event.type]
  final EventHandler? onBackgroundEventReceived;

  /// Stream of connectivity result
  /// Visible for testing
  @visibleForTesting
  final Stream<ConnectivityResult>? connectivityStream;

  @override
  StreamChatCoreState createState() => StreamChatCoreState();

  /// Use this method to get the current [StreamChatCoreState] instance
  static StreamChatCoreState of(BuildContext context) {
    StreamChatCoreState? streamChatState;

    streamChatState = context.findAncestorStateOfType<StreamChatCoreState>();

    assert(
      streamChatState != null,
      'You must have a StreamChat widget at the top of your widget tree',
    );

    return streamChatState!;
  }
}

/// State class associated with [StreamChatCore].
class StreamChatCoreState extends State<StreamChatCore>
    with WidgetsBindingObserver {
  /// Initialized client used throughout the application.
  StreamChatClient get client => widget.client;

  Timer? _disconnectTimer;

  @override
  Widget build(BuildContext context) => widget.child;

  /// The current user
  User? get user => client.state.user;

  /// The current user as a stream
  Stream<User?> get userStream => client.state.userStream;

  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;

  var _isInForeground = true;
  var _isConnectionAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _connectivitySubscription =
        (widget.connectivityStream ?? Connectivity().onConnectivityChanged)
            .listen((ConnectivityResult result) async {
      _isConnectionAvailable = result != ConnectivityResult.none;
      if (!_isInForeground) {
        return;
      }
      if (_isConnectionAvailable) {
        if (client.wsConnectionStatus == ConnectionStatus.disconnected) {
          await client.connect();
        }
      } else {
        if (client.wsConnectionStatus == ConnectionStatus.connected) {
          await client.disconnect();
        }
      }
    });
  }

  StreamSubscription? _eventSubscription;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isInForeground = state == AppLifecycleState.resumed;
    if (user != null) {
      if (!_isInForeground) {
        _onBackground();
      } else {
        _onForeground();
      }
    }
  }

  void _onForeground() {
    if (_disconnectTimer?.isActive == true) {
      _eventSubscription?.cancel();
      _disconnectTimer?.cancel();
    } else if (client.wsConnectionStatus == ConnectionStatus.disconnected &&
        _isConnectionAvailable) {
      client.connect();
    }
  }

  void _onBackground() {
    if (widget.onBackgroundEventReceived == null) {
      if (client.wsConnectionStatus != ConnectionStatus.disconnected) {
        client.disconnect();
      }
      return;
    }
    _eventSubscription = client.on().listen(
          widget.onBackgroundEventReceived,
        );

    void onTimerComplete() {
      _eventSubscription?.cancel();
      client.disconnect();
    }

    _disconnectTimer = Timer(widget.backgroundKeepAlive, onTimerComplete);
    return;
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _eventSubscription?.cancel();
    _disconnectTimer?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
