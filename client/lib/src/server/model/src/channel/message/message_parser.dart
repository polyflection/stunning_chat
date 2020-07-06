library message_parser;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:client_server/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:string_scanner/string_scanner.dart';

import '../../../server.dart';
import '../../data/data.dart' as data;

class MessageParser {
  Members _members;
  Iterable<data.Channel> _channels;
  StreamSubscription<Members> _membersSubscription;
  StreamSubscription<Iterable<data.Channel>> _channelsSubscription;

  Future<void> initialize(
      Stream<Members> members, Stream<Iterable<data.Channel>> channels) async {
    _members = await members.first;
    _channels = await channels.first;
    _membersSubscription = members.listen((event) => _members = event);
    _channelsSubscription = channels.listen((event) => _channels = event);
  }

  MessageBody parse(String messageBody) {
    assert(_members != null && _channels != null);
    return parseMessageBody(messageBody, _members, _channels);
  }

  Future<void> dispose() async {
    await _membersSubscription.cancel();
    await _channelsSubscription.cancel();
  }
}

const _mentionPrefixPattern = r'@';
const _channelPrefixPattern = r'#';

// Line break means \n.
const _codeUnitOfLineBreak = 10;

@visibleForTesting
MessageBody parseMessageBody(String messageBody, Iterable<Member> members,
    Iterable<data.Channel> channels) {
  final result = MessageBody._(
      hasTrailingNewLineEscapeSequence:
          _hasTrailingNewLineEscapeSequence(messageBody),
      debugSourceText: messageBody);
  final mentionPattern = _buildMentionPattern(members);
  final channelPattern = _buildChannelPattern(channels);

  for (final messageLine in LineSplitter.split(messageBody)) {
    result._addLine(_parseMessageLine(
        messageLine, mentionPattern, channelPattern, channels));
  }

  return result;
}

const _defaultMentionList = ['@everyone', '@here'];

bool _hasTrailingNewLineEscapeSequence(String messageBody) {
  if (messageBody.isEmpty) return false;
  return messageBody.codeUnits.last == _codeUnitOfLineBreak;
}

/// Example: (@everyone|@here|@john|@太郎|@山川　花子)
RegExp _buildMentionPattern(Iterable<Member> members) {
  final list = members.map((m) => '$_mentionPrefixPattern${m.name}').toList()
    ..addAll(_defaultMentionList);
  return RegExp('(${list.join('|')})');
}

/// Example: (#general|#random)
RegExp _buildChannelPattern(Iterable<data.Channel> channels) {
  return RegExp(
      '(${channels.map((c) => '$_channelPrefixPattern${c.name}').join('|')})');
}

MessageLine _parseMessageLine(String messageLine, RegExp mentionPattern,
    RegExp channelPattern, Iterable<data.Channel> channels) {
  if (messageLine.isEmpty) return MessageLine._();

  try {
    final result = MessageLine._();
    final scanner = StringScanner(messageLine);
    final plainTextCharacters = <int>[];
    do {
      if (scanner.matches(RegExp(urlSchemePattern))) {
        if (scanner.scan(RegExp(urlPattern))) {
          _addPlainTextToken(result, plainTextCharacters);
          final urlString = scanner.lastMatch[0];
          // Special treatment for '.', ',', '?', and '!'.
          // Since people often write them right after a URL,
          // such as "http://example.com." or "http://example.com,",
          // while they are valid part of URL.
          // So this treatment can break the valid URLs.
          // I believe it should be pretty rare event.
          // A precedent: Slack's message parsing seems to handle them in the same way.
          if (urlString.endsWith('.') ||
              urlString.endsWith(',') ||
              urlString.endsWith('?') ||
              urlString.endsWith('!')) {
            result._addToken(
                UrlToken._(urlString.substring(0, urlString.length - 1)));
            plainTextCharacters
                .addAll(urlString.substring(urlString.length - 1).codeUnits);
          } else {
            result._addToken(UrlToken._(urlString));
          }
        }
      } else if (scanner.matches(_mentionPrefixPattern)) {
        if (scanner.scan(mentionPattern)) {
          _addPlainTextToken(result, plainTextCharacters);
          result._addToken(MentionToken._(scanner.lastMatch[0]));
        } else {
          plainTextCharacters.add(scanner.readChar());
        }
      } else if (scanner.matches(_channelPrefixPattern)) {
        if (scanner.scan(channelPattern)) {
          _addPlainTextToken(result, plainTextCharacters);
          final channelNameWithPrefix = scanner.lastMatch[0];
          final channelName = channelNameWithPrefix.substring(1);
          final channel =
              channels.firstWhere((element) => element.name == channelName);
          result._addToken(ChannelToken._(channelNameWithPrefix, channel.id));
        } else {
          plainTextCharacters.add(scanner.readChar());
        }
      } else {
        plainTextCharacters.add(scanner.readChar());
      }
    } while (!scanner.isDone);

    scanner.expectDone();

    if (plainTextCharacters.isNotEmpty) {
      _addPlainTextToken(result, plainTextCharacters);
    }
    return result;
  } catch (e, s) {
    // Catch all potential exceptions.
    // TODO: Use Timer to prevent from infinite loop.
    debugPrint('message body parsing error: ${e.toString()}');
    debugPrint(s.toString());
    return MessageLine._().._addToken(PlainTextToken._(messageLine));
  }
}

void _addPlainTextToken(MessageLine result, List<int> plainTextCharacters) {
  if (plainTextCharacters.isNotEmpty) {
    result
        ._addToken(PlainTextToken._(String.fromCharCodes(plainTextCharacters)));
    plainTextCharacters.clear();
  }
}

enum TokenType { url, mention, channel, plainText }

abstract class Token {
  TokenType get type;
  String get string;
}

class UrlToken implements Token {
  UrlToken._(this.string);
  @override
  final TokenType type = TokenType.url;
  @override
  final String string;
}

class MentionToken implements Token {
  MentionToken._(this.string);
  @override
  final TokenType type = TokenType.mention;
  @override
  final String string;
}

class ChannelToken implements Token {
  ChannelToken._(this.string, this.channelId);
  @override
  final TokenType type = TokenType.channel;
  @override
  final String string;
  final String channelId;
  String get channelName => string;
}

class PlainTextToken implements Token {
  PlainTextToken._(this.string);
  @override
  final TokenType type = TokenType.plainText;
  @override
  final String string;
}

class MessageBody {
  MessageBody._(
      {@required bool hasTrailingNewLineEscapeSequence,
      @required this.debugSourceText})
      : _hasTrailingNewLineEscapeSequence = hasTrailingNewLineEscapeSequence;

  final List<MessageLine> _messageLines = [];
  final _hasTrailingNewLineEscapeSequence;
  final String debugSourceText;

  UnmodifiableListView<MessageLine> get lines =>
      UnmodifiableListView(_messageLines);

  void _addLine(MessageLine line) {
    _messageLines.add(line);
  }

  @override
  String toString() {
    var result = _messageLines.join('\n');
    if (_hasTrailingNewLineEscapeSequence) {
      result += '\n';
    }
    return result;
  }
}

/// MessageLine.
///
/// If [tokens] is empty, it means blank line.
class MessageLine {
  MessageLine._();

  final List<Token> _tokens = [];

  UnmodifiableListView<Token> get tokens => UnmodifiableListView(_tokens);

  void _addToken(Token token) {
    _tokens.add(token);
  }

  @override
  String toString() {
    return _tokens.fold(
        '', (previousValue, element) => previousValue + element.string);
  }
}
