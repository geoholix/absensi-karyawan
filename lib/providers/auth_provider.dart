import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _fetchUserData(user.uid);
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user;

      if (kIsWeb) {
        // Use Firebase's built-in web popup authentication
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        UserCredential userCredential = await _auth.signInWithPopup(authProvider);
        user = userCredential.user;
      } else {
        // Use google_sign_in for Android/iOS
        if (!_isGoogleSignInInitialized) {
          try {
            await _googleSignIn.initialize();
          } catch (e) {
            print('GoogleSignIn init caught (likely hot restart): $e');
          }
          _isGoogleSignInInitialized = true;
        }
        
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final GoogleSignInAuthorizationClient authClient = googleUser.authorizationClient;
        final GoogleSignInClientAuthorization? clientAuth = await authClient.authorizationForScopes([]);
        
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: clientAuth?.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user;
      }

      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Create new user with default role 'Karyawan'
          UserModel newUser = UserModel(
            uid: user.uid,
            idKaryawan: '', // To be filled by Admin
            nama: user.displayName ?? '',
            email: user.email ?? '',
            bagian: '',
            role: 'Karyawan',
            lokasiKerja: 'Pramuka',
            honorNormal: 0,
            honorLibur: 0,
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
          _userModel = newUser;
        } else {
          _userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error signing in with Google: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }
}
