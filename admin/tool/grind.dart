import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:admin/src/firebase/settings.dart';
import 'package:args/args.dart';
import 'package:grinder/grinder.dart';

String _flavor;

void main(args) {
  final parser = ArgParser()..addOption(_flavorOption);
  _flavor = parser.parse(args)[_flavorOption];
  _checkFlavorIsNotNull();
  grind(args);
}

@Task()
void deploy_cloud_functions() async {
  _checkFlavorIsNotNull();

  final projectId = await _getProjectId();
  await io.Process.run('grind', ['deploy', '--project=$projectId'],
          workingDirectory: '../server')
      .then((result) {
    io.stdout.write(result.stdout);
    io.stderr.write(result.stderr);
  });
}

@Task()
@Depends(delete_all_firestore_data)
void initialize_firestore_data() async {
  _checkFlavorIsNotNull();

  await _withFirebaseSettings(_flavor, () async {
    await io.Process.start(
            'node', ['node/build/bin/initialize_firestore_data.dart.js'])
        .then((result) {
      io.stdout.write(result.stdout);
      io.stderr.write(result.stderr);
    });
  });
}

@Task()
@Depends(build)
void delete_all_firestore_data() async {
  final projectId = await _getProjectId();
  await io.Process.start('firebase', [
    'firestore:delete',
    '--all-collections',
    '-y',
    '--project=$projectId'
  ]).then((result) {
    io.stdout.write(result.stdout);
    io.stderr.write(result.stderr);
  });
}

@Task()
void test() => TestRunner().testAsync();

@DefaultTask()
@Depends(test)
void build() async {
  await Pub.runAsync('build_runner',
      arguments: ['build', '--output=node/build']);
}

@Task()
void clean() async {
  await io.Process.run('rm', ['-rf', 'node/build']).then((result) {
    if (result.exitCode == 0) {
      print('Removed node/build directory.');
    }
    io.stdout.write(result.stdout);
    io.stderr.write(result.stderr);
  });
}

Future<void> _withFirebaseSettings(
    String flavor, Future<void> Function() callback) async {
  await _firebaseSettingsFile(flavor).copy(settingsFileName);
  await callback();
  await io.File(settingsFileName).delete();
}

io.File _firebaseSettingsFile(String flavor) {
  return io.File(settingsPathOfFlavor(flavor));
}

Future<String> _getProjectId() async {
  final jsonString = await _firebaseSettingsFile(_flavor).readAsString();
  return FirebaseSettings.fromJson(convert.jsonDecode(jsonString)).projectId;
}

void _checkFlavorIsNotNull() {
  if (_flavor == null) {
    throw ArgumentError(
        'flavor option must not be null. Example: --flavor=dev .');
  }
}

const _flavorOption = 'flavor';
