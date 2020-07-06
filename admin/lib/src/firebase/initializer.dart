import 'dart:convert' as convert;

import 'package:admin/src/firebase/settings.dart';
import 'package:firebase_admin_interop/firebase_admin_interop.dart' as admin;
import 'package:meta/meta.dart';
import 'package:node_io/node_io.dart' as io;

admin.App initializeApp(
    {@required String projectId, @required String serviceAccountKeyFilename}) {
  assert(projectId != null);
  assert(serviceAccountKeyFilename != null);

  final instance = admin.FirebaseAdmin.instance;
  final cert = instance.certFromPath(serviceAccountKeyFilename);
  return instance
      .initializeApp(admin.AppOptions(projectId: projectId, credential: cert));
}

Future<FirebaseSettings> getFirebaseSettings() async {
  final jsonString = await io.File(settingsFileName).readAsString();
  final settings = convert.jsonDecode(jsonString);
  return FirebaseSettings.fromJson(settings);
}
