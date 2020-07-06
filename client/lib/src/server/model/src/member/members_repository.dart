import 'package:client_server/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../authentication/model/data/user.dart' as auth_data;
import '../../../../firestore/firestore.dart';
import '../../server.dart';
import '../../src/data/data.dart' as server_data;

class MembersRepository with FirestoreInstance {
  MembersRepository(this._serverId);
  final String _serverId;

  Stream<Iterable<DataChange<server_data.Member>>> get dataChanges {
    return firestore
        .collection(firestorePath.members(_serverId).toString())
        .orderBy(CreatedAt.fieldName)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.documentChanges.map((change) {
          var changeType;
          switch (change.type) {
            case DocumentChangeType.added:
              changeType = ChangeType.added;
              break;
            case DocumentChangeType.modified:
              changeType = ChangeType.modified;
              break;
            case DocumentChangeType.removed:
              changeType = ChangeType.removed;
              break;
          }
          return DataChange(changeType, _toData(change.document),
              change.oldIndex, change.newIndex);
        });
      },
    );
  }

  server_data.Member _toData(DocumentSnapshot snapshot) {
    final json = snapshot.data;
    convertTimeStampToDateTimeString(json, [CreatedAt.fieldName]);
    final documentData = MemberDocumentData.fromJson(json);

    return server_data.Member(server_data.UserId(snapshot.documentID),
        documentData.name, documentData.createdAt);
  }

  Future<You> joinIfNotYet(auth_data.AnonymousUser user) async {
    final dRef =
        firestore.document(firestorePath.member(_serverId, user.id).toString());
    final ds = await dRef.get(source: Source.server);
    if (ds.exists) {
      assert(user.id == ds.documentID);
      return You(_toData(ds));
    } else {
      await dRef.setData({'name': user.name, 'createdAt': Timestamp.now()});
      final ds = await dRef.get(source: Source.server);
      return You(_toData(ds));
    }
  }
}
