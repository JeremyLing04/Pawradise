import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as MyUser; // Avoid conflict with Firebase User

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email, password, username, and display name
  Future<User?> signUp(String email, String password, String username, String name) async {
    try {
      print('🔐 Attempting to create user: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      print('✅ Firebase Auth user created: ${userCredential.user?.uid}');

      await _createUserDocument(userCredential.user!.uid, email, username, name);
      return userCredential.user;

    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      if (_isPigeonBug(e)) return await _handlePigeonBugAfterAuth(email, username, name);
      throw _getAuthErrorMessage(e.code);

    } catch (e) {
      print('❌ Unexpected error: $e');
      if (_isPigeonBug(e)) return await _handlePigeonBugAfterAuth(email, username, name);
      rethrow;
    }
  }

  // Handle plugin bug after sign-up
  Future<User?> _handlePigeonBugAfterAuth(String email, String username, String name) async {
    await Future.delayed(Duration(seconds: 2));
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email == email) {
      print('✅ User actually created: ${currentUser.uid}');
      await _createUserDocument(currentUser.uid, email, username, name);
      return currentUser;
    } else {
      throw 'User creation failed due to plugin error';
    }
  }

  // Handle plugin bug after login
  Future<User?> _handlePigeonBugAfterLogin() async {
    await Future.delayed(Duration(seconds: 2));
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      print('✅ User actually signed in: ${currentUser.uid}');
      await _ensureUserDocumentExists(currentUser);
      return currentUser;
    } else {
      throw 'Login failed due to plugin error';
    }
  }

  // Create Firestore user document
  Future<void> _createUserDocument(String userId, String email, String username, String name) async {
    print('📝 Creating Firestore document for user: $userId');
    try {
      final user = MyUser.User.createNew(id: userId, email: email, username: username, name: name);
      await _firestore.collection('users').doc(userId).set(user.toMap(), SetOptions(merge: true));
      print('✅ User document created/updated successfully');
    } catch (firestoreError) {
      print('❌ Firestore error: $firestoreError');
      throw 'Profile creation failed but you can still login: $firestoreError';
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      print('🔐 Signing in: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('✅ Sign in successful: ${userCredential.user?.uid}');

      if (userCredential.user != null) await _ensureUserDocumentExists(userCredential.user!);
      return userCredential.user;

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw _getAuthErrorMessage(e.code);

    } catch (e) {
      print('❌ Other Error: $e');
      if (_isPigeonBug(e)) return await _handlePigeonBugAfterLogin();
      throw 'Login failed. Please try again';
    }
  }

  // Ensure Firestore user document exists
  Future<void> _ensureUserDocumentExists(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('⚠️ User document missing, creating now...');
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': user.email,
          'username': user.displayName ?? 'User${user.uid.substring(0, 8)}',
          'karmaPoints': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('❌ Error ensuring user document exists: $e');
    }
  }

  // Detect plugin bug
  bool _isPigeonBug(dynamic error) {
    final errorString = error.toString();
    return errorString.contains("List<Object?>") && errorString.contains("PigeonUserDetails");
  }

  // Sign out
  Future<void> signOut() async => await _auth.signOut();

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Failed to send password reset email';
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) await user.sendEmailVerification();
  }

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Email verification status
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Map Firebase Auth errors to user-friendly messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password': return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email': return 'The email address is not valid.';
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'user-disabled': return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many failed attempts. Please try later.';
      case 'operation-not-allowed': return 'Email/password accounts are not enabled.';
      case 'network-request-failed': return 'Network error. Please check your connection.';
      case 'invalid-credential': return 'The supplied auth credential is invalid or expired.';
      default: return 'An error occurred: $errorCode. Please try again.';
    }
  }
}
