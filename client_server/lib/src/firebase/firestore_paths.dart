import 'package:meta/meta.dart';

final FirestorePath firestorePath = const FirestorePath._();

class FirestorePath {
  const FirestorePath._();
  Path server(String serverDocumentId) =>
      Path._([_serversCollectionId, serverDocumentId]);
  Path members(String serverDocumentId) =>
      server(serverDocumentId).._addId(_membersCollectionId);
  Path member(String serverDocumentId, String memberDocumentId) =>
      server(serverDocumentId)
        .._addIds([_membersCollectionId, memberDocumentId]);
  Path channels(String serverDocumentId) =>
      server(serverDocumentId).._addId(channelsCollectionId);
  Path channel(String serverDocumentId, String channelDocumentId) =>
      channels(serverDocumentId).._addId(channelDocumentId);
  Path channelNames(String serverDocumentId) => server(serverDocumentId)
    .._addIds([_channelNamesCollectionId, _soleDocumentId]);
  Path messages(String serverDocumentId, String channelDocumentId) =>
      channel(serverDocumentId, channelDocumentId)
        .._addId(messagesCollectionId);

  static const _serversCollectionId = 'servers';
  static const _membersCollectionId = 'members';
  static const channelsCollectionId = 'channels';
  static const _channelNamesCollectionId = 'channelNames';
  static const messagesCollectionId = 'messages';
  static const _soleDocumentId = 'soleDocumentId';
}

const soleDocumentId = FirestorePath._soleDocumentId;
const soleInstance = 'soleInstance';
const defaultChannelName = 'general';

class Path {
  final List<String> _ids;
  Path._(this._ids);

  Path({@required List<String> ids}) : _ids = ids;

  String get id => _ids.last;

  @override
  String toString() => _ids.join('/');

  void _addId(String id) {
    _ids.add(id);
  }

  void _addIds(List<String> ids) {
    _ids.addAll(ids);
  }
}
