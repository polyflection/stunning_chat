import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'channel/channels_repository.dart';
import 'channel/message/message_parser.dart';
import 'channel/message/message_position_storage.dart';
import 'channel/message/messages_repository.dart';
import 'member/members_repository.dart';

@immutable
class ServerRepositories {
  final String _serverId;
  final SharedPreferences _sharedPreferences;
  ServerRepositories(this._serverId, this._sharedPreferences);

  ChannelCreatingRepository channelCreatingRepository() =>
      ChannelCreatingRepository(_serverId);
  ChannelsRepository channelsRepository() => ChannelsRepository(_serverId);
  MembersRepository membersRepository() => MembersRepository(_serverId);
  MessagesRepository messagesRepository(
          String channelId, MessageParser messageParser) =>
      MessagesRepository(_serverId, channelId, messageParser);
  MessageAddingRepository messageAddingRepository(String channelId) =>
      MessageAddingRepository(_serverId, channelId);
  MessagePositionStorage messagePositionStorage() =>
      MessagePositionStorage(_sharedPreferences);
}
