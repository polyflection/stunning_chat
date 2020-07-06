import 'package:stunning_chat_app/src/server/model/server.dart';
import 'package:test/test.dart';

void main() {
  group('MessageReadPosition findIndexIn', () {
    test('found sample 1.', () {
      final sentAt = DateTime(2020, 6, 1);
      final result = ReadPosition.findIndexOf(sentAt, [sentAt]);
      expect(result, 0);
    });
    test('found sample 2.', () {
      final sentAt = DateTime(2020, 6, 2);
      final result = ReadPosition.findIndexOf(sentAt, [
        DateTime(2020, 6, 1),
        sentAt,
        DateTime(2020, 6, 3),
      ]);
      expect(result, 1);
    });
    test('Not exactly found sample 1.', () {
      final sentAt = DateTime(2020, 6, 2);
      final result = ReadPosition.findIndexOf(sentAt, [
        DateTime(2020, 6, 1),
        DateTime(2020, 6, 3),
      ]);
      expect(result, 0);
    });
    test('Not exactly found sample 2.', () {
      final sentAt = DateTime(2020, 6, 2);
      final result = ReadPosition.findIndexOf(sentAt, []);
      expect(result, 0);
    });
    test('Not exactly found sample 3.', () {
      final sentAt = DateTime(2020, 6, 2);
      final result = ReadPosition.findIndexOf(sentAt, [
        DateTime(2020, 5, 30),
        DateTime(2020, 6, 1),
        DateTime(2020, 6, 3),
        DateTime(2020, 6, 4)
      ]);
      expect(result, 1);
    });
  });
}
