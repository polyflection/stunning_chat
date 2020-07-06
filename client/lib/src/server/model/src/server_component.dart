library server;

import 'dart:async';

import '../../../authentication/model/data/user.dart' as user_data;
import '../server.dart';
import 'channel/channels.dart';
import 'channel/message/message_parser.dart';
import 'data/data.dart' as data;
import 'member/members.dart';
import 'member/members_repository.dart';
import 'server_repositories.dart';

EnterServer enter = (String serverId, user_data.AnonymousUser user,
    ServerRepositoriesConstructor serverRepositoriesConstructor) async {
  final repositories = serverRepositoriesConstructor(serverId);
  final you =
      await _EnteringServer(user, repositories.membersRepository()).run();
  final serverData = data.Server(serverId, soleServerName);
  return ServerComponent._(serverData, you, repositories);
};

LeaveServer leave = (Server server) async {
  // TODO: delete my membership.
  ServerComponent serverComponent = server;
  serverComponent._leavedController.add(null);
  await Future.delayed(Duration.zero, () => serverComponent._dispose());
  return true;
};

/// Server component.
///
/// Note: the boring part is to pass parameters down to sub components manually.
/// It can be improved with dependency Injection or Service locator library.
class ServerComponent implements Server {
  final ChannelsComponent _channels;
  final MembersComponent _members;
  final MessageParser _messageParser;
  final _leavedController = StreamController<void>.broadcast();
  final data.Server _data;

  factory ServerComponent._(
      data.Server serverData, You you, ServerRepositories repositories) {
    final parser = MessageParser();
    final channels = ChannelsComponent(you, parser, repositories);
    final members = MembersComponent(you, repositories.membersRepository());
    return ServerComponent.__(serverData, channels, members, parser);
  }

  ServerComponent.__(
      this._data, this._channels, this._members, this._messageParser) {
    _initialize();
  }

  void _initialize() async {
    await Future.wait([
      _members.initialize(),
      _channels.initialize(),
      _messageParser.initialize(_members.members, _channels.channelDataSet)
    ]);
    // initialize current channel after the message parser is ready.
    await _channels.initializeCurrent();
  }

  @override
  Sink<String> get switchChannelById => _channels.switchCurrentById;

  @override
  Stream<String> get name => Stream.value(_data.name);
  @override
  Stream<You> get you => Stream.value(_members.you);
  @override
  Stream<Channel> get currentChannel => _channels.current;
  @override
  Stream<ChannelStatuses> get channels => _channels.channelList;
  @override
  Stream<ChannelForm> get channelForm => _channels.form;
  @override
  Stream<Members> get members => _members.members;
  @override
  Stream<void> get leaved => _leavedController.stream;

  void _dispose() async {
    await _channels.dispose();
    await _members.dispose();
    await _messageParser.dispose();
    await _leavedController.close();
  }
}

class _EnteringServer {
  _EnteringServer(this._you, this._membersRepository);
  final user_data.AnonymousUser _you;
  final MembersRepository _membersRepository;

  Future<You> run() => _membersRepository.joinIfNotYet(_you);
}
