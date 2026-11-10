import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorHandler {
  static String getMessage(Object error) {
    // Firebase Authentication Errors
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
          return 'Incorrect email or password. Please try again.';

        case 'user-not-found':
          return 'No account found with this email.';

        case 'wrong-password':
          return 'Incorrect password.';

        case 'email-already-in-use':
          return 'An account with this email already exists.';

        case 'weak-password':
          return 'Password should be at least 6 characters long.';

        case 'invalid-email':
          return 'Please enter a valid email address.';

        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';

        case 'network-request-failed':
          return 'Please check your internet connection.';

        case 'user-disabled':
          return 'This account has been disabled.';

        case 'requires-recent-login':
          return 'Please log in again before performing this action.';

        case 'popup-closed-by-user':
          return 'Sign-in was cancelled.';

        case 'account-exists-with-different-credential':
          return 'This email is already linked to another sign-in method.';

        case 'operation-not-allowed':
          return 'This sign-in method is currently unavailable.';

        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }

    // Firestore Errors
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';

        case 'not-found':
          return 'The requested data could not be found.';

        case 'already-exists':
          return 'This record already exists.';

        case 'unavailable':
          return 'The service is temporarily unavailable. Please try again later.';

        case 'deadline-exceeded':
          return 'The request timed out. Please try again.';

        case 'cancelled':
          return 'The operation was cancelled.';

        case 'aborted':
          return 'The operation could not be completed. Please try again.';

        case 'resource-exhausted':
          return 'The service is currently busy. Please try again later.';

        case 'failed-precondition':
          return 'The operation cannot be completed at this time.';

        case 'unauthenticated':
          return 'Please log in and try again.';

        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
