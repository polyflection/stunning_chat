import 'dart:async';

import 'package:client_server/firebase.dart';
import 'package:rxdart/rxdart.dart';

import '../../server.dart' as i;
import '../data/data.dart' as data;
import '../server_repositories.dart';
import 'channel.dart';
import 'channel_form.dart';
import 'message/message_parser.dart';

class ChannelsComponent {
  final _switchCurrentController = StreamController<String>();
  final _channels = BehaviorSubject<List<ChannelComponent>>.seeded([]);
  final _currentChannel = BehaviorSubject<ChannelComponent>();
  final _channelStatuses = BehaviorSubject<i.ChannelStatuses>();

  final i.You _you;
  final MessageParser _messageParser;
  final ServerRepositories _serverRepositories;

  StreamSubscription _channelsSubscription;

  ChannelsComponent(this._you, this._messageParser, this._serverRepositories);

  Sink<String> get switchCurrentById => _switchCurrentController.sink;

  Stream<i.Channel> get current => _currentChannel.stream;

  Stream<Iterable<data.Channel>> get channelDataSet => _channels.stream
      .where((list) => list.isNotEmpty)
      .map((channels) => channels.map((e) => e.data));

  Stream<ChannelForm> get form async* {
    yield ChannelForm(
        _you,
        _channels.stream.map((cList) => cList.map((c) => c.data.name)),
        _serverRepositories.channelCreatingRepository(),
        onCompleted: (newChannelId) async {
      await _channels.firstWhere((channels) =>
          channels.any((channel) => channel.data.id == newChannelId));
      _switchChannelById(newChannelId);
    });
  }

  Stream<i.ChannelStatuses> get channelList => _channelStatuses.stream;

  Future<void> dispose() async {
    await _channelsSubscription?.cancel();
    await _switchCurrentController.close();
    _channels.value.forEach((channel) => channel.dispose());
    await _channelStatuses.close();
    await _currentChannel.close();
  }

  Future<void> initialize() async {
    _channelsSubscription = _serverRepositories
        .channelsRepository()
        .dataChanges
        .listen(_handleChannelChanges);
    _switchCurrentController.stream.listen(_switchChannelById);

    // TODO: restore info of which channel is current one from a local storage.
    await channelDataSet.first.then((dataSet) {
      final channel = _channels.value
          .firstWhere((channel) => channel.data.id == dataSet.first.id);
      _switchCurrentChannelTo(channel);
    });
  }

  void _switchChannelById(String channelId) {
    final channel =
        _channels.value.firstWhere((channel) => channel.data.id == channelId);
    _switchCurrentChannelTo(channel);
  }

  void _switchCurrentChannelTo(ChannelComponent channel) {
    if (!channel.hasRunInitializer) {
      channel.initialize();
    }
    _currentChannel.value = channel;
    _buildChannelStatuses(_currentChannel.value);
  }

  void _handleChannelChanges(Iterable<DataChange<data.Channel>> dataChanges) {
    final channels = _channels.value;

    for (final change in dataChanges) {
      switch (change.type) {
        case ChangeType.added:
          channels.insert(
              change.newIndex,
              ChannelComponent(
                  change.data, _you, _messageParser, _serverRepositories));
          break;
        case ChangeType.modified:
          if (change.oldIndex == change.newIndex) {
            final channel = channels[change.newIndex];
            assert(channel.data.id == change.data.id);
            channel.updateData(change.data);
          } else {
            final channel = channels.removeAt(change.oldIndex);
            channel.updateData(change.data);
            channels.insert(change.newIndex, channel);
          }
          break;
        case ChangeType.removed:
          final channel = channels.removeAt(change.oldIndex);
          assert(_currentChannel.value != null);
          if (channel.data.id == _currentChannel.value.data.id) {
            _switchCurrentChannelTo(channels.first);
          }
          channel.dispose();
          break;
      }
    }

    _channels.value = channels;
    _buildChannelStatuses(_currentChannel.value);
  }

  Future<void> initializeCurrent() async {
    if (_currentChannel.value.hasRunInitializer) return;
    await _currentChannel.value.initialize();
  }

  void _buildChannelStatuses(ChannelComponent /*nullable*/ currentChannel) {
    _channelStatuses.value = i.ChannelStatuses(_channels.value.map((c) =>
        i.ChannelStatus(
            c.data.id, c.data.name, c.data.id == currentChannel?.data?.id)));
  }
}
