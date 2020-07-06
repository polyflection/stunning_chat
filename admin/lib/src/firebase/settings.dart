enum Flavor { dev, integration_test }
const settingsBaseName = 'node/firebase_settings';
const settingsFileName = '$settingsBaseName.json';
String settingsPathOfFlavor(String flavor) =>
    '${settingsBaseName}_for_$flavor.json';

class FirebaseSettings {
  final String flavor;
  final String projectId;
  final String serviceAccountKeyFilename;
  factory FirebaseSettings.fromJson(Map<String, dynamic> json) =>
      FirebaseSettings(
          json['flavor'], json['projectId'], json['serviceAccountKeyFilename']);
  FirebaseSettings(this.flavor, this.projectId, this.serviceAccountKeyFilename)
      : assert(flavor != null),
        assert(projectId != null),
        assert(serviceAccountKeyFilename != null);
}
