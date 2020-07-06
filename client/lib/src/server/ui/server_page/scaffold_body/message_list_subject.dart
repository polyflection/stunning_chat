import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../../../resource_provider.dart';
import '../../../model/server.dart' as model;

class MessageListSubject implements Resource {
  final model.Channel _channel;
  final ItemScrollController scrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final model.ChannelSwitcher _channelSwitcher;
  final Completer<void> _initializingCompleter = Completer();
  bool _markedMessageSent = false;
  StreamSubscription<String> _messageSentSubscription;

  MessageListSubject(this._channel, this._channelSwitcher) {
    _initialize();
  }

  Stream<ScrollablePositionedListData> get scrollablePositionedListData async* {
    await _initializingCompleter.future;

    final messagesQueue = StreamQueue(_channel.messages);

    var currentMessages = await messagesQueue.next;
    var uniqueKey = UniqueKey();

    yield ScrollablePositionedListData._fromReadPositions(
        currentMessages,
        uniqueKey,
        await _channel.messageLastReadPosition.first,
        await _channel.messageAlreadyReadPosition.first);

    yield* messagesQueue.rest.asyncMap((newMessages) async {
      var initialScrollIndex;
      var initialAlignment;

      // If the newMessages object has older messages,
      // then re-initialize the ScrollablePositionedList
      // with the initialScrollIndex that preserves perceived scroll position.
      if (currentMessages.isNotEmpty &&
          newMessages.isNotEmpty &&
          newMessages.length != currentMessages.length &&
          newMessages.first.sentAt != null &&
          currentMessages.first.sentAt != null &&
          newMessages.first.sentAt.isBefore(currentMessages.first.sentAt)) {
        final diff = newMessages.length - currentMessages.length;
        if (diff > 0) {
          // New parameter for the re-initialized ScrollablePositionedList.
          initialScrollIndex = diff;

          final positions = itemPositionsListener.itemPositions.value;
          if (positions.isNotEmpty) {
            // It preserves the alignment.
            initialAlignment = _minPosition(positions).itemLeadingEdge;
          }

          // It will make ScrollablePositionedList re-initialize.
          uniqueKey = UniqueKey();
        }
      }

      currentMessages = newMessages;

      final alreadyReadIndex =
          ScrollablePositionedListData._findAlreadyReadIndex(
              await _channel.messageAlreadyReadPosition.first, currentMessages);

      return ScrollablePositionedListData._(currentMessages, uniqueKey,
          initialScrollIndex: initialScrollIndex,
          initialAlignment: initialAlignment,
          alreadyReadIndex: alreadyReadIndex);
    }).doOnData(_maybeScrollToBottomAfterNextBuild);
  }

  bool shouldShowUnreadSeparator(
      int index, int /* nullable */ alreadyReadIndex) {
    if (alreadyReadIndex == null) return false;
    return alreadyReadIndex == index;
  }

  Future<void> launchUrl(String url) async {
    if (await url_launcher.canLaunch(url)) {
      await url_launcher.launch(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  void switchChannel(String channelId) {
    _channelSwitcher.switchChannelById.add(channelId);
  }

  @override
  void dispose() async {
    await _messageSentSubscription?.cancel();
  }

  void _initialize() async {
    itemPositionsListener.itemPositions.addListener(_scrollListener);
    _messageSentSubscription = _channel.messageSent.listen((_) {
      _markedMessageSent = true;
    });
    _initializingCompleter.complete();
  }

  void _scrollListener() async {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final messages = await _channel.messages.first;
    if (messages.isEmpty) return;

    final min = _minPosition(positions);
    final max = _maxPosition(positions);

    _channel.messageReadPosition.add(model.ReadPosition(
        messages[max.index].sentAt ?? DateTime.now(), max.itemLeadingEdge));

    if (_isItemPositionNearTop(min)) {
      _channel.messagePagination.add(model.MessagePagination.previous);
    } else if (_isItemPositionNearBottom(max, messages.length - 1)) {
      _channel.messagePagination.add(model.MessagePagination.next);
    }
  }

  ItemPosition _minPosition(Iterable<ItemPosition> positions) {
    assert(positions != null);
    assert(positions.isNotEmpty);
    return positions.where((position) => position.itemTrailingEdge > 0).reduce(
        (min, position) =>
            position.itemTrailingEdge < min.itemTrailingEdge ? position : min);
  }

  ItemPosition _maxPosition(Iterable<ItemPosition> positions) {
    assert(positions != null);
    assert(positions.isNotEmpty);
    return positions.where((position) => position.itemLeadingEdge < 1).reduce(
        (max, position) =>
            position.itemLeadingEdge > max.itemLeadingEdge ? position : max);
  }

  bool _isItemPositionNearTop(ItemPosition min) =>
      min.index <= 3 && min.itemLeadingEdge < 0.9;

  bool _isItemPositionNearBottom(ItemPosition max, int messageLastIndex) =>
      max.index >= messageLastIndex - 2 && max.itemTrailingEdge > 0.1;

  void _maybeScrollToBottomAfterNextBuild(ScrollablePositionedListData data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_markedMessageSent) {
        _markedMessageSent = false;
        final positions = itemPositionsListener.itemPositions.value;
        if (positions.isEmpty) return;
        if (_maxPosition(positions).itemTrailingEdge < 0.9) return;
      } else {
        final positions = itemPositionsListener.itemPositions.value;
        if (positions.isEmpty) return;
        if (_maxPosition(positions).itemTrailingEdge < 0.9) return;
        final maxIndex = data.messages.length - 1;
        final maxIndexInViewport = _maxPosition(positions).index;
        if (maxIndex - maxIndexInViewport > 1) return;
      }

      // When the messages size is zero, the scrollController is not attached.
      if (!scrollController.isAttached) return;
      if (data.messages.isEmpty) return;

      scrollController.scrollTo(
          index: data.messages.length - 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeIn);
    });
  }
}

// Converter outside model for view.
// One could prefer to move this method into model.Messages,
// and define MessageView class,
// if one strictly obey the BLoC rule.
String toDateTimeView(DateTime dateTime) {
  if (dateTime == null) return null;
  return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
}

// Converter outside model for view.
// One could prefer to move this method into model.Messages,
// and define MessageView class,
// if one strictly obey the BLoC rule.
String toDayView(DateTime dateTime) {
  if (dateTime == null) return null;
  return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
}

class ScrollablePositionedListData {
  final model.Messages messages;
  final UniqueKey key;
  final int initialScrollIndex;
  final double initialAlignment;
  final int alreadyReadIndex;

  factory ScrollablePositionedListData._fromReadPositions(
      model.Messages messages,
      UniqueKey key,
      model.ReadPosition lastReadPosition,
      model.ReadPosition alreadyReadPosition) {
    int initialScrollIndex;
    double initialAlignment;

    if (lastReadPosition != null) {
      initialScrollIndex = lastReadPosition.findIndexIn(messages);
      initialAlignment = lastReadPosition.leadingEdge;
    } else {
      initialScrollIndex = messages.isEmpty ? 0 : messages.length - 1;
      initialAlignment = 0.0;
    }

    return ScrollablePositionedListData._(messages, key,
        initialScrollIndex: initialScrollIndex,
        initialAlignment: initialAlignment,
        alreadyReadIndex: _findAlreadyReadIndex(alreadyReadPosition, messages));
  }

  ScrollablePositionedListData._(this.messages, this.key,
      {@required int initialScrollIndex,
      @required double initialAlignment,
      @required int alreadyReadIndex})
      : initialScrollIndex = initialScrollIndex ??
            0, // 0 is ScrollablePositionedList's default value.
        initialAlignment = initialAlignment ??
            0.0, // 0.0 is ScrollablePositionedList's default value.
        alreadyReadIndex = alreadyReadIndex ?? 0,
        assert(messages != null),
        assert(key != null);

  static int _findAlreadyReadIndex(
      model.ReadPosition alreadyReadPosition, model.Messages messages) {
    return alreadyReadPosition != null
        ? alreadyReadPosition.findIndexIn(messages)
        : 0;
  }
}
