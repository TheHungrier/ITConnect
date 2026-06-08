import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendResetPasswordEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser => _auth.currentUser;
}