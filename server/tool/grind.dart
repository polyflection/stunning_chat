import 'dart:io';

import 'package:args/args.dart';
import 'package:grinder/grinder.dart';

String _projectId;

void main(args) {
  final parser = ArgParser()..addOption(_projectIdOption);
  _projectId = parser.parse(args)[_projectIdOption];
  _checkProjectIdIsNotNull();
  grind(args);
}

@Task()
@Depends(build)
void deploy() async {
  _checkProjectIdIsNotNull();
  await Process.start('firebase', [
    'deploy',
    '--only',
    'functions',
    '--project=$_projectId'
  ]).then((result) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  });
}

@DefaultTask()
void build() async {
  await Pub.runAsync('build_runner',
      arguments: ['build', '--output=$_buildDirectory']);
}

@Task()
void watch() async {
  await Pub.runAsync('build_runner',
      arguments: ['watch', '--output=$_buildDirectory']);
}

@Task()
void clean() async {
  await Process.run('rm', ['-rf', _buildDirectory]).then((result) {
    if (result.exitCode == 0) {
      print('Removed $_buildDirectory directory.');
    }
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  });
}

@Task()
void npm_install() async {
  await Process.start('npm', ['install'], workingDirectory: _functionsDirectory)
      .then((result) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  });
}

const _functionsDirectory = 'functions';
const _buildDirectory = '$_functionsDirectory/build';

const _projectIdOption = 'project';

void _checkProjectIdIsNotNull() {
  if (_projectId == null) {
    throw ArgumentError(
        '$_projectIdOption option must not be null. Example: --$_projectIdOption=a_project_id .');
  }
}
