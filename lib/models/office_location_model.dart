import 'package:cloud_firestore/cloud_firestore.dart';

class OfficeLocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool requireGeofencing;
  final int radius;
  final bool hasShifts;

  OfficeLocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.requireGeofencing,
    required this.radius,
    required this.hasShifts,
  });

  factory OfficeLocationModel.fromMap(Map<String, dynamic> map, String docId) {
    return OfficeLocationModel(
      id: docId,
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      requireGeofencing: map['require_geofencing'] ?? false,
      radius: map['radius'] ?? 50,
      hasShifts: map['has_shifts'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'require_geofencing': requireGeofencing,
      'radius': radius,
      'has_shifts': hasShifts,
    };
  }
}
