import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._firebaseAuth, this._firestore);

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream to listen to auth changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Register with email and password
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role, // 'user' or 'staff'
  }) async {
    try {
      print('📝 Starting registration for: $email with role: $role');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      if (userCredential.user != null) {
        print(
          '💾 Creating user document in Firestore for: ${userCredential.user!.uid}',
        );
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'phoneNumber': phone,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User document created successfully with role: $role');
      }

      return userCredential;
    } catch (e) {
      print('❌ Error registering: $e');
      rethrow;
    }
  }

  // Login with email and password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Error logging in: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error logging out: $e');
      rethrow;
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  // Get current user email
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  // Get current user name
  String? get currentUserName => _firebaseAuth.currentUser?.displayName;

  // Get current user UID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Get user document from Firestore
  Future<Map<String, dynamic>?> getUserDocument(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('Error fetching user document: $e');
      return null;
    }
  }

  // Update user document
  Future<void> updateUserDocument(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      print('🔥 updateUserDocument called with userId: $userId');
      print('📊 Data to update: $data');

      await _firestore.collection('users').doc(userId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true → create if not exists

      print('✅ updateUserDocument success!');
    } catch (e) {
      print('❌ Error updating user document: $e');
      rethrow;
    }
  }
}
