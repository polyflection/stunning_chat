library server;

import 'dart:collection';

import 'package:client_server/firebase.dart';
import 'package:client_server/model.dart';
import 'package:flutter/foundation.dart';

import '../../authentication/model/authentication.dart' show AnonymousUser;
import '../../form_library/form_library.dart';
import 'src/channel/message/message_parser.dart';
import 'src/channel/message/messages_paginator.dart' show MessagePagination;
import 'src/channel/message/read_positions.dart';
import 'src/data/data.dart';
import 'src/server_component.dart' as server_component;
import 'src/server_repositories.dart';

export 'package:client_server/model.dart';

export 'src/channel/message/message_parser.dart'
    show
        MessageBody,
        TokenType,
        Token,
        UrlToken,
        PlainTextToken,
        ChannelToken,
        MentionToken;
export 'src/channel/message/messages_paginator.dart' show MessagePagination;
export 'src/channel/message/read_positions.dart' show ReadPosition;

part 'server/channels.dart';
part 'server/channels/messages.dart';
part 'server/members.dart';

// The current system has sole server of this fixed id and name.
const soleServerId = soleDocumentId;
const soleServerName = soleInstance;

// Server interface (BLoC interface).
abstract class Server {
  Sink<String> get switchChannelById;
  Stream<String> get name;
  Stream<You> get you;
  Stream<Members> get members;
  Stream<ChannelStatuses> get channels;
  Stream<Channel> get currentChannel;
  Stream<ChannelForm> get channelForm;
  Stream<void> get leaved;
}

typedef EnterServer = Future<Server> Function(
    String serverId,
    AnonymousUser user,
    ServerRepositoriesConstructor serverRepositoriesConstructor);

EnterServer enterServer = server_component.enter;

// Because Dart can not parameterize class, use closure instead.
typedef ServerRepositoriesConstructor = ServerRepositories Function(
    String serverId);

typedef LeaveServer = Future<bool> Function(Server server);

LeaveServer leaveServer = server_component.leave;
