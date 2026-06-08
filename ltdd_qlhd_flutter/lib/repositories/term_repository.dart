import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/term_model.dart';

class TermRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<TermModel>> getTerms() {
    final user = _auth.currentUser;

    if (user == null) {
      return _getSystemTermsStream();
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('myActivities')
        .snapshots()
        .asyncMap((myActivitiesSnapshot) async {
          final termsMap = <String, TermModel>{};

          final systemTermsSnapshot = await _db
              .collection('terms')
              .where('isActive', isEqualTo: true)
              .get();

          for (final doc in systemTermsSnapshot.docs) {
            final term = TermModel.fromFirestore(doc);
            termsMap[term.id] = term;
          }

          for (final doc in myActivitiesSnapshot.docs) {
            final data = doc.data();

            final status = data['status']?.toString() ?? '';
            if (status == 'cancelled') continue;

            final termId = data['termId']?.toString().trim() ?? '';
            if (termId.isEmpty) continue;

            if (termsMap.containsKey(termId)) continue;

            termsMap[termId] = TermModel.fromTermId(
              termId: termId,
              schoolYear: data['academicYear'] ?? data['schoolYear'],
              semester: data['semester'],
              startAt: _toDateTimeNullable(data['startAt']),
              endAt: _toDateTimeNullable(data['endAt']),
            );
          }

          final terms = termsMap.values.toList();

          terms.sort((a, b) {
            final orderCompare = b.order.compareTo(a.order);

            if (orderCompare != 0) {
              return orderCompare;
            }

            return b.id.compareTo(a.id);
          });

          return terms;
        });
  }

  Stream<List<TermModel>> _getSystemTermsStream() {
    return _db
        .collection('terms')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final terms = snapshot.docs
              .map((doc) => TermModel.fromFirestore(doc))
              .toList();

          terms.sort((a, b) {
            final orderCompare = b.order.compareTo(a.order);

            if (orderCompare != 0) {
              return orderCompare;
            }

            return b.id.compareTo(a.id);
          });

          return terms;
        });
  }

  DateTime? _toDateTimeNullable(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
