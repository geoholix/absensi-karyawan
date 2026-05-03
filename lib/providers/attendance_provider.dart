import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/payroll_model.dart';
import '../models/office_location_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  AttendanceModel? _todayAttendance;
  AttendanceModel? get todayAttendance => _todayAttendance;

  OfficeLocationModel? _officeLocation;
  OfficeLocationModel? get officeLocation => _officeLocation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchOfficeLocation(String locationId) async {
    try {
      var doc = await _firestore.collection(Collections.officeLocations).doc(locationId).get();
      if (doc.exists) {
        _officeLocation = OfficeLocationModel.fromMap(doc.data()!, doc.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching office location: $e');
    }
  }

  Future<void> fetchTodayAttendance(String uid) async {
    String today = Formatters.isoDateKey(DateTime.now());
    var snapshot = await _firestore
        .collection(Collections.attendance)
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

  Stream<List<AttendanceModel>> getAttendanceHistory(String uid) {
    return _firestore
        .collection(Collections.attendance)
        .where('uid', isEqualTo: uid)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<PayrollModel>> getPayrollHistory(String uid) {
    return _firestore
        .collection(Collections.payroll)
        .where('uid', isEqualTo: uid)
        .orderBy('periode_akhir', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PayrollModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
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

  /// Throws a user-facing message string if [pos] is outside the configured
  /// office geofence. No-op when geofencing is disabled or unconfigured.
  void _validateGeofence(Position pos) {
    final office = _officeLocation;
    if (office == null || !office.requireGeofencing) return;

    final distance = Geolocator.distanceBetween(
      pos.latitude, pos.longitude,
      office.latitude, office.longitude,
    );
    if (distance > office.radius) {
      throw 'Anda berada di luar area kantor! Jarak Anda: ${distance.toStringAsFixed(0)}m (Maks: ${office.radius}m)';
    }
  }

  Future<Uint8List> _processImage(XFile file, Position pos) async {
    final Uint8List bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    String date = Formatters.stamp.format(DateTime.now());
    String coords = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
    String text = '$date\n$coords';

    // Add text watermark (simple approach)
    img.drawString(image, text, font: img.arial24, x: 20, y: image.height - 60, color: img.ColorRgb8(255, 255, 0));

    return Uint8List.fromList(img.encodeJpg(image));
  }

  Future<String> _uploadData(Uint8List data, String path) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask = ref.putData(data);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
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

      _validateGeofence(pos);

      String today = Formatters.isoDateKey(DateTime.now());
      String fileName = '${user.uid}_${today}_in.jpg';

      // Process with watermark
      Uint8List processedData = await _processImage(photo, pos);
      String photoUrl = await _uploadData(processedData, 'attendance/$fileName');

      AttendanceModel newRecord = AttendanceModel(
        uid: user.uid,
        tanggal: today,
        waktuMasuk: DateTime.now(),
        lokasiMasuk: GeoPoint(pos.latitude, pos.longitude),
        fotoMasukUrl: photoUrl,
        shiftAktual: user.lokasiKerja == Shifts.pramuka ? Shifts.pramuka : shift,
        status: AttendanceStatus.masuk,
      );

      DocumentReference docRef = await _firestore.collection(Collections.attendance).add(newRecord.toMap());
      _todayAttendance = AttendanceModel.fromMap(newRecord.toMap(), docRef.id);
    } catch (e) {
      debugPrint('Check-in error: $e');
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

      _validateGeofence(pos);

      String today = Formatters.isoDateKey(DateTime.now());
      String fileName = '${user.uid}_${today}_out.jpg';

      // Process with watermark
      Uint8List processedData = await _processImage(photo, pos);
      String photoUrl = await _uploadData(processedData, 'attendance/$fileName');

      DateTime now = DateTime.now();

      // Calculate Hours
      Map<String, double> hours = _calculateWorkingHours(
        _todayAttendance!.waktuMasuk!,
        now,
        _todayAttendance!.shiftAktual,
      );

      await _firestore.collection(Collections.attendance).doc(_todayAttendance!.idAbsen).update({
        'waktu_pulang': Timestamp.fromDate(now),
        'lokasi_pulang': GeoPoint(pos.latitude, pos.longitude),
        'foto_pulang_url': photoUrl,
        'total_jam_normal': hours['normal'],
        'total_jam_lembur': hours['lembur'],
        'status': AttendanceStatus.selesai,
      });

      await fetchTodayAttendance(user.uid);
    } catch (e) {
      debugPrint('Check-out error: $e');
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

    if (shift == Shifts.pramuka) {
      normalStart = const TimeOfDay(hour: 7, minute: 0);
      normalEnd = const TimeOfDay(hour: 16, minute: 0);
    } else if (shift == Shifts.pagi) {
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

  Future<void> submitLeave(String uid, DateTime start, DateTime end, String alasan) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection(Collections.leaves).add({
        'uid': uid,
        'tanggal_mulai': Timestamp.fromDate(start),
        'tanggal_selesai': Timestamp.fromDate(end),
        'alasan': alasan,
        'status': LeaveStatus.pending,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error submitting leave: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
