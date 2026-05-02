import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  AttendanceModel? _todayAttendance;
  AttendanceModel? get todayAttendance => _todayAttendance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchTodayAttendance(String uid) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var snapshot = await _firestore
        .collection('attendance')
        .where('uid', isEqualTo: uid)
        .where('tanggal', isEqualTo: today)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      _todayAttendance = AttendanceModel.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } else {
      _todayAttendance = null;
    }
    notifyListeners();
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<XFile?> _takeSelfie() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );
  }

  Future<String> _uploadFile(XFile file, String path) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask;
    
    if (kIsWeb) {
      uploadTask = ref.putData(await file.readAsBytes());
    } else {
      uploadTask = ref.putFile(File(file.path));
    }
    
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> checkIn(UserModel user, String shift) async {
    _isLoading = true;
    notifyListeners();

    try {
      XFile? photo = await _takeSelfie();
      if (photo == null) throw 'Foto selfie diperlukan.';

      Position? pos = await _getCurrentLocation();
      if (pos == null) throw 'Gagal mendapatkan lokasi GPS.';

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String fileName = '${user.uid}_${today}_in.jpg';
      String photoUrl = await _uploadFile(photo, 'attendance/$fileName');

      AttendanceModel newRecord = AttendanceModel(
        uid: user.uid,
        tanggal: today,
        waktuMasuk: DateTime.now(),
        lokasiMasuk: GeoPoint(pos.latitude, pos.longitude),
        fotoMasukUrl: photoUrl,
        shiftAktual: user.lokasiKerja == 'Pramuka' ? 'Pramuka' : shift,
        status: 'Masuk',
      );

      DocumentReference docRef = await _firestore.collection('attendance').add(newRecord.toMap());
      _todayAttendance = AttendanceModel.fromMap(newRecord.toMap(), docRef.id);
    } catch (e) {
      print('Check-in error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkOut(UserModel user) async {
    if (_todayAttendance == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      XFile? photo = await _takeSelfie();
      if (photo == null) throw 'Foto selfie diperlukan.';

      Position? pos = await _getCurrentLocation();
      if (pos == null) throw 'Gagal mendapatkan lokasi GPS.';

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String fileName = '${user.uid}_${today}_out.jpg';
      String photoUrl = await _uploadFile(photo, 'attendance/$fileName');

      DateTime now = DateTime.now();
      
      // Calculate Hours
      Map<String, double> hours = _calculateWorkingHours(
        _todayAttendance!.waktuMasuk!,
        now,
        _todayAttendance!.shiftAktual,
      );

      await _firestore.collection('attendance').doc(_todayAttendance!.idAbsen).update({
        'waktu_pulang': Timestamp.fromDate(now),
        'lokasi_pulang': GeoPoint(pos.latitude, pos.longitude),
        'foto_pulang_url': photoUrl,
        'total_jam_normal': hours['normal'],
        'total_jam_lembur': hours['lembur'],
        'status': 'Selesai',
      });

      await fetchTodayAttendance(user.uid);
    } catch (e) {
      print('Check-out error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, double> _calculateWorkingHours(DateTime masuk, DateTime pulang, String shift) {
    // Basic Logic based on requirements
    // Pramuka: 7:00 - 16:00 (9 hours total, usually 8 working + 1 break)
    // Non-Pramuka Pagi: 7:30 - 16:30
    // Non-Pramuka Malam: 19:30 - 04:30
    
    TimeOfDay normalStart;
    TimeOfDay normalEnd;

    if (shift == 'Pramuka') {
      normalStart = const TimeOfDay(hour: 7, minute: 0);
      normalEnd = const TimeOfDay(hour: 16, minute: 0);
    } else if (shift == 'Pagi') {
      normalStart = const TimeOfDay(hour: 7, minute: 30);
      normalEnd = const TimeOfDay(hour: 16, minute: 30);
    } else { // Malam
      normalStart = const TimeOfDay(hour: 19, minute: 30);
      normalEnd = const TimeOfDay(hour: 4, minute: 30);
    }

    // Simplify: Total difference in hours
    double totalHours = pulang.difference(masuk).inMinutes / 60.0;
    
    // This is a complex area, for now we'll assume:
    // If total hours > 9, anything above 8 is overtime (adjust based on specific business rules later)
    // Real implementation should check the actual overlap with normalStart/normalEnd.
    
    double normal = totalHours > 8 ? 8 : totalHours;
    double lembur = totalHours > 8 ? totalHours - 8 : 0;

    return {'normal': normal, 'lembur': lembur};
  }
}
