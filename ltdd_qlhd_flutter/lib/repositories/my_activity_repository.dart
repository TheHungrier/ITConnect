import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/my_activity_model.dart';

class MyActivityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<MyActivityModel>> getMyActivities() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('myActivities')
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                return MyActivityModel.fromMyActivityData(
                  registrationId: doc.id,
                  data: doc.data(),
                );
              })
              .where((activity) => activity.status != 'cancelled')
              .toList();
        });
  }
}
