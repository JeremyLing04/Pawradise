//services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUp(String email, String password, String username) async {
    try {
      print('🔐 Attempting to create user: $email');
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase Auth user created: ${userCredential.user?.uid}');
      
      await _createUserDocument(userCredential.user!.uid, email, username);
      
      return userCredential.user;
      
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      
      if (_isPigeonBug(e)) {
        print('⚠️ Plugin bug detected, checking if user was actually created');
        return await _handlePigeonBugAfterAuth(email, username);
      }
      
      throw _getAuthErrorMessage(e.code);
      
    } catch (e) {
      print('❌ Unexpected error: $e');
      
      if (_isPigeonBug(e)) {
        print('⚠️ Plugin bug detected, checking if user was actually created');
        return await _handlePigeonBugAfterAuth(email, username);
      }
      
      rethrow;
    }
  }

Future<User?> signIn(String email, String password) async {
  try {
    print('🔐 Signing in: $email');
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    print('✅ Sign in successful: ${userCredential.user?.uid}');
    
    if (userCredential.user != null) {
      await _ensureUserDocumentExists(userCredential.user!);
    }
    
    return userCredential.user;
    
  } on FirebaseAuthException catch (e) {
    print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
    throw _getAuthErrorMessage(e.code); // 使用友好的错误消息
    
  } catch (e) {
    print('❌ Other Error: $e');
    
    if (_isPigeonBug(e)) {
      print('⚠️ Plugin bug detected, checking if user was actually signed in');
      return await _handlePigeonBugAfterLogin();
    }
    
    throw '登录失败，请重试';
  }
}

  Future<User?> _handlePigeonBugAfterAuth(String email, String username) async {
    await Future.delayed(Duration(seconds: 2));
    
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email == email) {
      print('✅ User was actually created: ${currentUser.uid}');
      await _createUserDocument(currentUser.uid, email, username);
      return currentUser;
    } else {
      throw 'User creation failed due to plugin error';
    }
  }

  Future<User?> _handlePigeonBugAfterLogin() async {
    await Future.delayed(Duration(seconds: 2));
    
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      print('✅ User was actually signed in: ${currentUser.uid}');
      await _ensureUserDocumentExists(currentUser);
      return currentUser;
    } else {
      throw 'Login failed due to plugin error';
    }
  }

  // services/auth_service.dart
  Future<void> _createUserDocument(String userId, String email, String username) async {
    print('📝 Creating Firestore document for user: $userId');
    
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'username': username,
        'bio': '', // ✅ 新增 bio 字段，默认为空
        'karmaPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ User document created/updated successfully');
      
    } catch (firestoreError) {
      print('❌ Firestore error: $firestoreError');
      throw 'Profile creation failed but you can still login: $firestoreError';
    }
  }

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

  bool _isPigeonBug(dynamic error) {
    final errorString = error.toString();
    return errorString.contains("List<Object?>") && 
          errorString.contains("PigeonUserDetails");
  }

  // 其他方法保持不变...
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Failed to send password reset email';
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential': 
        return 'The supplied auth credential is incorrect, malformed or has expired.';
      default:
        return 'An error occurred: $errorCode. Please try again.';
    }
  }
}