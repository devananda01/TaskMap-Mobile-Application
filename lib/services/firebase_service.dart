import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/user_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService;

  FirebaseService({UserService? userService})
    : _userService = userService ?? UserService();
  //Authentication
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      clientId:
          '338951668004-l5taa823clv9k2r6ro01ubhpe78u4s5e.apps.googleusercontent.com',
    ).signIn();

    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      await _userService.ensureUserDocument(userCredential.user!);
    }

    return userCredential;
  }

  // GitHub Sign-In
  Future<UserCredential> signInWithGitHub() async {
    GithubAuthProvider githubProvider = GithubAuthProvider();

    final userCredential = kIsWeb
        ? await _auth.signInWithPopup(githubProvider)
        : await _auth.signInWithProvider(githubProvider);
        
    if (userCredential.user != null) {
      await _userService.ensureUserDocument(userCredential.user!);
    }

    return userCredential;
  }

  Future<void> logout() async {
    await _auth.signOut();
    print("Current User: ${_auth.currentUser}");
  }

  // Password Reset
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;

    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  bool isEmailVerified() {
    User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.emailVerified;
  }

  //change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser!;

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    await user.updatePassword(newPassword);
  }
}
