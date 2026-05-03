import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/office_location_model.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> updateUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Stream<List<OfficeLocationModel>> getOfficeLocationsStream() {
    return _firestore.collection('office_locations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return OfficeLocationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addOfficeLocation(OfficeLocationModel location) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('office_locations').doc(location.id).set(location.toMap());
    } catch (e) {
      print('Error adding office location: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOfficeLocation(OfficeLocationModel location) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('office_locations').doc(location.id).update(location.toMap());
    } catch (e) {
      print('Error updating office location: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteOfficeLocation(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('office_locations').doc(id).delete();
    } catch (e) {
      print('Error deleting office location: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
