import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/office_location_model.dart';
import '../utils/constants.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminProvider() {
    // Keep [_users] live so screens that read `.users` synchronously
    // (daily attendance, leave approvals, etc.) get the populated list.
    _usersSub = _firestore.collection(Collections.users).snapshots().listen(
      (snapshot) {
        _users = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();
        notifyListeners();
      },
      onError: (e) => debugPrint('AdminProvider users stream error: $e'),
    );
  }

  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _usersSub;

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _usersSub.cancel();
    super.dispose();
  }

  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection(Collections.users).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> updateUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection(Collections.users).doc(user.uid).update(user.toMap());
    } catch (e) {
      debugPrint('Error updating user: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Stream<List<OfficeLocationModel>> getOfficeLocationsStream() {
    return _firestore.collection(Collections.officeLocations).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return OfficeLocationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addOfficeLocation(OfficeLocationModel location) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection(Collections.officeLocations).doc(location.id).set(location.toMap());
    } catch (e) {
      debugPrint('Error adding office location: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOfficeLocation(OfficeLocationModel location) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection(Collections.officeLocations).doc(location.id).update(location.toMap());
    } catch (e) {
      debugPrint('Error updating office location: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteOfficeLocation(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection(Collections.officeLocations).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting office location: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
