import 'package:stunning_chat_app/src/server/model/server.dart';
import 'package:stunning_chat_app/src/server/model/src/channel/message/message_parser.dart';
import 'package:stunning_chat_app/src/server/model/src/data/data.dart' as data;
import 'package:test/test.dart';

void main() {
  group('parseMessageBody', () {
    final members = [
      ['a', 'John'],
      ['b', '太郎'],
      ['c', '山川　花子'],
      ['d', 'with絵文字🤗emoticon😥😂name😈'],
    ].map((e) => data.Member(data.UserId(e.first), e.last, DateTime.now()));
    final aTime = DateTime.now();
    final channels = [
      ['a', 'general'],
      ['b', 'random'],
      ['c', 'にほん語チャンネル'],
      ['d', '😈👻💩'],
    ].map((e) => data.Channel(e.first, e.last, aTime));

    test('Simple case. Plain text only.', () {
      final input = 'Hi there!';

      final result = parseMessageBody(input, members, channels);
      expect(result.lines.length == 1, isTrue);
      expect(result.lines.first.tokens.length == 1, isTrue);
      final token = result.lines.first.tokens.first;
      expect(token.type, TokenType.plainText);
      expect(token.string, input);
    });

    test('Empty message.', () {
      final input = '';
      final result = parseMessageBody(input, members, channels);
      expect(result.lines, hasLength(0));
      expect(result.toString(), input);
    });

    group('With mention.', () {
      test('Simple.', () {
        final input = 'Hello @everyone!';

        final result = parseMessageBody(input, members, channels);
        expect(result.lines, hasLength(1));
        expect(result.lines.first.tokens, hasLength(3));

        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hello ');

        final token2 = result.lines.first.tokens[1];
        expect(token2.type, TokenType.mention);
        expect(token2.string, '@everyone');

        final token3 = result.lines.first.tokens[2];
        expect(token3.type, TokenType.plainText);
        expect(token3.string, '!');
      });
      test('Without whitespace.', () {
        final input = 'Hello!@everyone.';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines, hasLength(1));
        expect(result.lines.first.tokens, hasLength(3));

        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hello!');

        final token2 = result.lines.first.tokens[1];
        expect(token2.type, TokenType.mention);
        expect(token2.string, '@everyone');

        final token3 = result.lines.first.tokens[2];
        expect(token3.type, TokenType.plainText);
        expect(token3.string, '.');
      });
      test('Without whitespace, to multiple names.', () {
        final input = 'こんにちは！@太郎@山川　花子。';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines, hasLength(1));
        expect(result.lines.first.tokens, hasLength(4));

        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'こんにちは！');

        final token2 = result.lines.first.tokens[1];
        expect(token2.type, TokenType.mention);
        expect(token2.string, '@太郎');
        final token3 = result.lines.first.tokens[2];
        expect(token3.type, TokenType.mention);
        expect(token3.string, '@山川　花子');

        final token4 = result.lines.first.tokens[3];
        expect(token4.type, TokenType.plainText);
        expect(token4.string, '。');
      });
      test('To a name which does not exist.', () {
        final input = 'Hi! @aStranger.';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines.first.tokens, hasLength(1));
        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hi! @aStranger.');
      });
      test('To a name which include emoticons.', () {
        final input = 'Hi! @with絵文字🤗emoticon😥😂name😈.';
        final result = parseMessageBody(input, members, channels);
        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hi! ');

        final token2 = result.lines.first.tokens[1];
        expect(token2.type, TokenType.mention);
        expect(token2.string, '@with絵文字🤗emoticon😥😂name😈');

        final token3 = result.lines.first.tokens[2];
        expect(token3.type, TokenType.plainText);
        expect(token3.string, '.');
      });
    });
    group('With channel.', () {
      test('Simple.', () {
        final input = 'Hello! Please visit #general.';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines.first.tokens, hasLength(3));
        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hello! Please visit ');

        final token2 = result.lines.first.tokens[1];
        expect(token2.type, TokenType.channel);
        expect(token2.string, '#general');

        final token3 = result.lines.first.tokens[2];
        expect(token3.type, TokenType.plainText);
        expect(token3.string, '.');
      });
      test('Without whitespace.', () {
        final input = 'Hello! Please visit#general.';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines.first.tokens, hasLength(3));
        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hello! Please visit');

        final token2 = result.lines.first.tokens[1];
        expect(token2.type, TokenType.channel);
        expect(token2.string, '#general');

        final token3 = result.lines.first.tokens[2];
        expect(token3.type, TokenType.plainText);
        expect(token3.string, '.');
      });
      test('Without whitespace, to multiple names.', () {
        final input = 'Hello! Please visit#generaland#random.';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines.first.tokens, hasLength(5));
        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hello! Please visit');

        final token2 = result.lines.first.tokens[1];
        expect(token2.type, TokenType.channel);
        expect(token2.string, '#general');

        final token3 = result.lines.first.tokens[2];
        expect(token3.type, TokenType.plainText);
        expect(token3.string, 'and');

        final token4 = result.lines.first.tokens[3];
        expect(token4.type, TokenType.channel);
        expect(token4.string, '#random');

        final token5 = result.lines.first.tokens[4];
        expect(token5.type, TokenType.plainText);
        expect(token5.string, '.');
      });
      test('To a name which does not exist.', () {
        final input = 'Hello! Please visit #feneral.';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines.first.tokens, hasLength(1));
        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hello! Please visit #feneral.');
      });
      test('To a name which include emoticons.', () {
        final input = 'Hello! Please visit #😈👻💩.';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines.first.tokens, hasLength(3));
        final token1 = result.lines.first.tokens.first;
        expect(token1.type, TokenType.plainText);
        expect(token1.string, 'Hello! Please visit ');

        final token2 = result.lines.first.tokens[1];
        expect(token2.type, TokenType.channel);
        expect(token2.string, '#😈👻💩');

        final token3 = result.lines.first.tokens[2];
        expect(token3.type, TokenType.plainText);
        expect(token3.string, '.');
      });
    });
    group('With URL.', () {
      final url = 'https://example.com/path/to/point?a=b&c=d';
      test('Simple', () {
        final input = url;
        final result = parseMessageBody(input, members, channels);
        final tokens = result.lines.first.tokens;
        expect(tokens, hasLength(1));
        final token = tokens.first;
        expect(token.type, TokenType.url);
        expect(token.string, 'https://example.com/path/to/point?a=b&c=d');
      });
      test('Without whitespaces.', () {
        final input = 'Hello!$url';
        final result = parseMessageBody(input, members, channels);
        final tokens = result.lines.first.tokens;
        expect(tokens, hasLength(2));
        final token = tokens.first;
        expect(token.type, TokenType.plainText);
        expect(token.string, 'Hello!');
        final token2 = tokens[1];
        expect(token2.type, TokenType.url);
        expect(token2.string, url);
      });
      test('With trailing "."', () {
        final input = 'Hello! $url.';
        final result = parseMessageBody(input, members, channels);
        final tokens = result.lines.first.tokens;
        expect(tokens, hasLength(3));
        expect(tokens.first.string, 'Hello! ');
        expect(tokens[1].string, url);
        expect(tokens.last.string, '.');
      });
      test('With trailing "."', () {
        final input = 'Hello! $url,';
        final result = parseMessageBody(input, members, channels);
        final tokens = result.lines.first.tokens;
        expect(tokens, hasLength(3));
        expect(tokens.first.type, TokenType.plainText);
        expect(tokens.first.string, 'Hello! ');
        expect(tokens[1].type, TokenType.url);
        expect(tokens[1].string, url);
        expect(tokens.last.type, TokenType.plainText);
        expect(tokens.last.string, ',');
      });
      test('With trailing "!"', () {
        final input = 'Hello! $url!';
        final result = parseMessageBody(input, members, channels);
        final tokens = result.lines.first.tokens;
        expect(tokens, hasLength(3));
        expect(tokens.first.type, TokenType.plainText);
        expect(tokens.first.string, 'Hello! ');
        expect(tokens[1].type, TokenType.url);
        expect(tokens[1].string, url);
        expect(tokens.last.type, TokenType.plainText);
        expect(tokens.last.string, '!');
      });
      test('With trailing "?"', () {
        final input = 'Hello! $url?';
        final result = parseMessageBody(input, members, channels);
        final tokens = result.lines.first.tokens;
        expect(tokens, hasLength(3));
        expect(tokens.first.type, TokenType.plainText);
        expect(tokens.first.string, 'Hello! ');
        expect(tokens[1].type, TokenType.url);
        expect(tokens[1].string, url);
        expect(tokens.last.type, TokenType.plainText);
        expect(tokens.last.string, '?');
      });
    });
    group('Multi line message.', () {
      test('Multi line message.', () {
        final input = '\nHello!\n\nGood bye!';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines, hasLength(4));
        final line1 = result.lines.first;
        expect(line1.tokens, isEmpty);
        expect(line1.toString(), '');
        expect(result.lines[0].toString(), '');
        expect(result.lines[1].toString(), 'Hello!');
        expect(result.lines[2].toString(), '');
        expect(result.lines[3].toString(), 'Good bye!');
        expect(result.toString(), input);
      });

      test('Multi line message 2.', () {
        final input = '\nHello!\n\nGood bye!\n\n';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines, hasLength(5));
        final line1 = result.lines.first;
        expect(line1.tokens, isEmpty);
        expect(line1.toString(), '');
        expect(result.lines[0].toString(), '');
        expect(result.lines[1].toString(), 'Hello!');
        expect(result.lines[2].toString(), '');
        expect(result.lines[3].toString(), 'Good bye!');
        expect(result.lines[4].toString(), '');
        expect(result.toString(), input);
      });
    });
    group('Complex case.', () {
      test('Complex case.', () {
        final input =
            'Hello!🤗@everyone❗️Please visit #general✊.\nThen...\nvisit #random.\n\nGood bye!\n';
        final result = parseMessageBody(input, members, channels);
        expect(result.lines, hasLength(5));
        expect(result.lines.first.tokens, hasLength(5));
        expect(result.toString(), input);
      });
    });
  });
}
