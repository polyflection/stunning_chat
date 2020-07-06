import 'package:firebase_admin_interop/firebase_admin_interop.dart' as admin;
export 'package:firebase_admin_interop/firebase_admin_interop.dart';

admin.App initializeApp() => admin.FirebaseAdmin.instance.initializeApp();
