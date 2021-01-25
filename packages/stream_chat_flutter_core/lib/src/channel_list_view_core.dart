import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:stream_chat_flutter_core/src/channels_bloc.dart';

import 'stream_chat_core.dart';

/// ![screenshot](https://raw.githubusercontent.com/GetStream/stream-chat-flutter/master/screenshots/channel_list_view.png)
/// ![screenshot](https://raw.githubusercontent.com/GetStream/stream-chat-flutter/master/screenshots/channel_list_view_paint.png)
///
/// It shows the list of current channels.
///
/// ```dart
/// class ChannelListPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: ChannelListView(
///         filter: {
///           'members': {
///             '\$in': [StreamChat.of(context).user.id],
///           }
///         },
///         sort: [SortOption('last_message_at')],
///         pagination: PaginationParams(
///           limit: 20,
///         ),
///         channelWidget: ChannelPage(),
///       ),
///     );
///   }
/// }
/// ```
///
///
/// Make sure to have a [StreamChatCore] ancestor in order to provide the information about the channels.
/// The widget uses a [ListView.custom] to render the list of channels.
///
/// The widget components render the ui based on the first ancestor of type [StreamChatTheme].
/// Modify it to change the widget appearance.
class ChannelListViewCore extends StatefulWidget {
  /// Instantiate a new ChannelListView
  ChannelListViewCore({
    Key key,
    this.filter,
    this.options,
    this.sort,
    this.pagination,
    this.pullToRefresh = true,
    @required this.errorBuilder,
    @required this.emptyBuilder,
    @required this.loadingBuilder,
    @required this.listBuilder,
    this.channelListController,
  }) : super(key: key);

  final ChannelListController channelListController;

  /// The builder that will be used in case of error
  final Widget Function(Error error) errorBuilder;

  final WidgetBuilder loadingBuilder;

  final Function(BuildContext, List<Channel>) listBuilder;

  /// The builder used when the channel list is empty.
  final WidgetBuilder emptyBuilder;

  /// The query filters to use.
  /// You can query on any of the custom fields you've defined on the [Channel].
  /// You can also filter other built-in channel fields.
  final Map<String, dynamic> filter;

  /// Query channels options.
  ///
  /// state: if true returns the Channel state
  /// watch: if true listen to changes to this Channel in real time.
  final Map<String, dynamic> options;

  /// The sorting used for the channels matching the filters.
  /// Sorting is based on field and direction, multiple sorting options can be provided.
  /// You can sort based on last_updated, last_message_at, updated_at, created_at or member_count.
  /// Direction can be ascending or descending.
  final List<SortOption> sort;

  /// Pagination parameters
  /// limit: the number of channels to return (max is 30)
  /// offset: the offset (max is 1000)
  /// message_limit: how many messages should be included to each channel
  final PaginationParams pagination;

  /// Set it to false to disable the pull-to-refresh widget
  final bool pullToRefresh;

  @override
  _ChannelListViewCoreState createState() => _ChannelListViewCoreState();
}

class _ChannelListViewCoreState extends State<ChannelListViewCore>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    final channelsBloc = ChannelsBloc.of(context);

    if (!widget.pullToRefresh) {
      return _buildListView(channelsBloc);
    }

    return RefreshIndicator(
      onRefresh: () async {
        return channelsBloc.queryChannels(
          filter: widget.filter,
          sortOptions: widget.sort,
          paginationParams: widget.pagination,
          options: widget.options,
        );
      },
      child: _buildListView(channelsBloc),
    );
  }

  StreamBuilder<List<Channel>> _buildListView(
    ChannelsBlocState channelsBlocState,
  ) {
    return StreamBuilder<List<Channel>>(
      stream: channelsBlocState.channelsStream,
      builder: (context, snapshot) {
        var child;
        if (snapshot.hasError) {
          child = _buildErrorWidget(
            snapshot,
            context,
            channelsBlocState,
          );
        } else if (!snapshot.hasData) {
          child = _buildLoadingWidget();
        } else {
          final channels = snapshot.data;

          child = widget.emptyBuilder(context);

          if (channels.isNotEmpty) {
            return widget.listBuilder(context, channels);
          }
        }

        return child;
      },
    );
  }

  Widget _buildLoadingWidget() {
    return widget.loadingBuilder(context);
  }

  Widget _buildErrorWidget(
    AsyncSnapshot<List<Channel>> snapshot,
    BuildContext context,
    ChannelsBlocState channelsBlocState,
  ) {
    if (snapshot.error is Error) {
      print((snapshot.error as Error).stackTrace);
    }

    return widget.errorBuilder(snapshot.error);
  }

  void loadData() {
    final channelsBloc = ChannelsBloc.of(context);

    channelsBloc.queryChannels(
      filter: widget.filter,
      sortOptions: widget.sort,
      paginationParams: widget.pagination,
      options: widget.options,
    );
  }

  void paginateData() {
    final channelsBloc = ChannelsBloc.of(context);

    channelsBloc.queryChannels(
      filter: widget.filter,
      sortOptions: widget.sort,
      paginationParams: widget.pagination.copyWith(
        offset: channelsBloc.channels?.length ?? 0,
      ),
      options: widget.options,
    );
  }

  StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    final channelsBloc = ChannelsBloc.of(context);
    channelsBloc.queryChannels(
      filter: widget.filter,
      sortOptions: widget.sort,
      paginationParams: widget.pagination,
      options: widget.options,
    );

    final client = StreamChatCore.of(context).client;

    _subscription = client
        .on(
      EventType.connectionRecovered,
      EventType.notificationAddedToChannel,
      EventType.notificationMessageNew,
      EventType.channelVisible,
    )
        .listen((event) {
      channelsBloc.queryChannels(
        filter: widget.filter,
        sortOptions: widget.sort,
        paginationParams: widget.pagination,
        options: widget.options,
      );
    });

    if (widget.channelListController != null) {
      widget.channelListController.loadData = loadData;
      widget.channelListController.paginateData = paginateData;
    }
  }

  @override
  void didUpdateWidget(ChannelListViewCore oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.filter?.toString() != oldWidget.filter?.toString() ||
        jsonEncode(widget.sort) != jsonEncode(oldWidget.sort) ||
        widget.pagination?.toJson()?.toString() !=
            oldWidget.pagination?.toJson()?.toString() ||
        widget.options?.toString() != oldWidget.options?.toString()) {
      final channelsBloc = ChannelsBloc.of(context);
      channelsBloc.queryChannels(
        filter: widget.filter,
        sortOptions: widget.sort,
        paginationParams: widget.pagination,
        options: widget.options,
      );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Controller used for paginating data in [ChannelListViewCore]
class ChannelListController {
  VoidCallback loadData;
  VoidCallback paginateData;
}
