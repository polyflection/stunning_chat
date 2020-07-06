import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:grinder/grinder.dart';

void main(args) => grind(args);

@Task()
void integration_test_app() async {
  await io.Process.start('flutter', [
    'drive',
    '--target=test_driver/app.dart',
    '--flavor=integration_test'
  ]).then((process) {
    io.stdout.addStream(process.stdout);
    io.stderr.addStream(process.stderr);
  });
}

@Task()
void test() async {
  await io.Process.start('flutter', ['test']).then((process) {
    io.stdout.addStream(process.stdout);
    io.stderr.addStream(process.stderr);
  });
}

@Task()
void clean() async {
  await io.Process.start('flutter', ['clean']).then((process) {
    io.stdout.addStream(process.stdout);
    io.stderr.addStream(process.stderr);
  });
}

@Task()
void load_firebase_google_services_json_for_integration_test() async {
  final json = convert.base64.decode(
      io.Platform.environment['ANDROID_FIREBASE_SECRET_FOR_INTEGRATION_TEST']);
  await io.File('android/app/src/integration_test/google-services.json')
      .writeAsString(String.fromCharCodes(json));
}
