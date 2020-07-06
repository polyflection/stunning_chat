import 'package:admin/firebase.dart';
import 'package:admin/src/firebase/initializer.dart';

void main() async {
  final settings = await getFirebaseSettings();
  final app = initializeApp(
      projectId: settings.projectId,
      serviceAccountKeyFilename: settings.serviceAccountKeyFilename);

  await initializeFirestoreData(app);
}
