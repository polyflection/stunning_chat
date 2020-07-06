import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../resource_provider.dart';
import '../../../../theme.dart';
import '../../../model/server.dart' as model;
import 'message_list_subject.dart';

class MessageList extends StatelessWidget {
  static Widget inSubject({
    Key key,
    @required model.Channel channel,
  }) {
    assert(channel != null);
    return ResourceProvider<MessageListSubject>(
      key: key,
      create: (context) => MessageListSubject(
          channel, Provider.of<model.ChannelSwitcher>(context, listen: false)),
      child: const MessageList._(),
    );
  }

  const MessageList._();

  @override
  Widget build(BuildContext context) {
    final subject = Provider.of<MessageListSubject>(context);

    return StreamBuilder<ScrollablePositionedListData>(
      stream: subject.scrollablePositionedListData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Column(children: [const LinearProgressIndicator()]);
        }

        final data = snapshot.data;
        final messages = data.messages;
        if (messages.isEmpty) {
          // Seems necessary since if a List is empty,
          // ScrollablePositionedList emits error
          // as "Invalid value: Not in range 0..n, inclusive: -1".
          return const SizedBox.shrink();
        }

        assert(messages.isNotEmpty);

        return Expanded(
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (OverscrollIndicatorNotification overScroll) {
              overScroll.disallowGlow();
              return true;
            },
            child: ScrollablePositionedList.separated(
              key: data.key,
              initialScrollIndex: data.initialScrollIndex,
              initialAlignment: data.initialAlignment,
              separatorBuilder: (context, index) {
                if (index == 0) return _transparentDivider;

                if (subject.shouldShowUnreadSeparator(
                    index, data.alreadyReadIndex)) {
                  return _MessageDivider(body: 'New');
                }

                final current = messages[index];
                final prev = messages[index - 1];
                if (current.sentAt != null &&
                    prev.sentAt != null &&
                    current.sentAt.day != prev.sentAt.day) {
                  return _MessageDivider(
                    body: toDayView(current.sentAt),
                  );
                }

                return _transparentDivider;
              },
              padding: const EdgeInsets.all(8),
              itemScrollController: subject.scrollController,
              itemPositionsListener: subject.itemPositionsListener,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                switch (message.type) {
                  case model.MessageType.member:
                    return _MemberMessageTile(
                      by: message.sender.name,
                      body: message.body,
                      sentAt: message.sentAt,
                    );
                  case model.MessageType.welcome:
                    return _WelcomeMessageTile(
                      messageBody: message.body,
                      sentAt: message.sentAt.toString(),
                    );
                  default:
                    throw ArgumentError();
                }
              },
            ),
          ),
        );
      },
    );
  }
}

const _transparentDivider = Divider(color: Colors.transparent, height: 1);

class _MessageDivider extends StatelessWidget {
  _MessageDivider({@required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Flexible(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(body),
          ),
          const Flexible(child: Divider()),
        ],
      ),
    );
  }
}

final arrowForwardIcon = Icon(
  Icons.arrow_forward,
  color: Colors.tealAccent[700],
);

class _WelcomeMessageTile extends StatelessWidget {
  _WelcomeMessageTile({@required this.messageBody, @required this.sentAt});
  final model.MessageBody messageBody;
  final String sentAt;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            height: 24,
            width: 48,
            child: arrowForwardIcon,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                children: <Widget>[
                  _WelcomeMessageBody(messageBody),
                  Text(
                    sentAt,
                    style: Theme.of(context)
                        .textTheme
                        .overline
                        .copyWith(color: greyTextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeMessageBody extends StatelessWidget {
  _WelcomeMessageBody(this._body);
  final model.MessageBody _body;
  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    for (final line in _body.lines) {
      final lineSpans = line.tokens.map((token) {
        switch (token.type) {
          case model.TokenType.plainText:
            return _plainTextSpan(token);
          case model.TokenType.url:
            return _urlTextSpan(token, context);
          case model.TokenType.channel:
            return _channelTextSpan(token, context);
          case model.TokenType.mention:
            return _mentionTextSpan(token);
          default:
            throw ArgumentError();
        }
      }).toList()
        ..add(const TextSpan(text: '\n')); // (a).
      spans.addAll(lineSpans);
    }
    // Remove new line escape sequence from last line added at (a).
    spans.removeLast();
    return Text.rich(TextSpan(children: spans));
  }

  TextSpan _plainTextSpan(model.PlainTextToken token) {
    return TextSpan(text: token.string, style: TextStyle(color: greyTextColor));
  }

  TextSpan _channelTextSpan(model.ChannelToken token, BuildContext context) {
    return TextSpan(
        text: token.string,
        style: TextStyle(
            color: Colors.indigo[300],
            backgroundColor: const Color.fromARGB(32, 114, 137, 218)),
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              Provider.of<MessageListSubject>(context, listen: false)
                  .switchChannel(token.channelId));
  }

  TextSpan _mentionTextSpan(model.MentionToken token) {
    return TextSpan(
        text: token.string,
        style: TextStyle(
            color: Colors.indigo[300],
            backgroundColor: const Color.fromARGB(32, 114, 137, 218)),
        recognizer: TapGestureRecognizer()
          ..onTap = () => debugPrint('Go to member page. Unimplemented.'));
  }

  TextSpan _urlTextSpan(model.UrlToken token, BuildContext context) {
    return TextSpan(
        text: token.string,
        style: TextStyle(color: Colors.blue[400]),
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              Provider.of<MessageListSubject>(context, listen: false)
                  .launchUrl(token.string));
  }
}

class _MemberMessageTile extends StatelessWidget {
  _MemberMessageTile({
    @required this.body,
    @required this.by,
    @required DateTime sentAt,
  })  : sentAt = toDateTimeView(sentAt),
        iconText = by.substring(0, 1);

  final model.MessageBody body;
  final String by;
  final String iconText;
  final String sentAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
              height: 48,
              width: 48,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    color: Theme.of(context).accentColor),
                child: Center(
                  child: Text(
                    iconText,
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        .copyWith(color: Colors.black),
                  ),
                ),
              )),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          text: by,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          children: [
                            WidgetSpan(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  sentAt ?? 'sending...',
                                  softWrap: true,
                                  style: Theme.of(context)
                                      .textTheme
                                      .overline
                                      .copyWith(color: greyTextColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _MemberMessageBody(body)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _MemberMessageBody extends StatelessWidget {
  final model.MessageBody _body;
  _MemberMessageBody(this._body);

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    for (final line in _body.lines) {
      final lineSpans = line.tokens.map((token) {
        switch (token.type) {
          case model.TokenType.plainText:
            return _plainTextSpan(token);
          case model.TokenType.url:
            return _urlTextSpan(token, context);
          case model.TokenType.channel:
            return _channelTextSpan(token, context);
          case model.TokenType.mention:
            return _mentionTextSpan(token);
          default:
            throw ArgumentError();
        }
      }).toList()
        ..add(const TextSpan(text: '\n')); // (a).
      spans.addAll(lineSpans);
    }
    // Remove new line escape sequence from last line added at (a).
    spans.removeLast();
    return Text.rich(TextSpan(children: spans));
  }

  TextSpan _plainTextSpan(model.PlainTextToken token) {
    return TextSpan(text: token.string);
  }

  TextSpan _channelTextSpan(model.ChannelToken token, BuildContext context) {
    return TextSpan(
        text: token.string,
        style: TextStyle(
            color: Colors.indigo[300],
            backgroundColor: const Color.fromARGB(32, 114, 137, 218)),
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              Provider.of<MessageListSubject>(context, listen: false)
                  .switchChannel(token.channelId));
  }

  TextSpan _mentionTextSpan(model.MentionToken token) {
    return TextSpan(
        text: token.string,
        style: TextStyle(
            color: Colors.indigo[300],
            backgroundColor: const Color.fromARGB(32, 114, 137, 218)),
        recognizer: TapGestureRecognizer()
          ..onTap = () => debugPrint('Go to member page. Unimplemented.'));
  }

  TextSpan _urlTextSpan(model.UrlToken token, BuildContext context) {
    return TextSpan(
        text: token.string,
        style: TextStyle(color: Colors.blue[400]),
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              Provider.of<MessageListSubject>(context, listen: false)
                  .launchUrl(token.string));
  }
}
