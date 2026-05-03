/// Centralized strings used as Firestore collection names, field names,
/// statuses, shifts, etc. Avoid sprinkling raw literals through the codebase.
library;

class Collections {
  Collections._();

  static const String users = 'users';
  static const String attendance = 'attendance';
  static const String payroll = 'payroll';
  static const String leaves = 'leaves';
  static const String officeLocations = 'office_locations';
}

class AttendanceStatus {
  AttendanceStatus._();

  static const String menunggu = 'Menunggu';
  static const String masuk = 'Masuk';
  static const String selesai = 'Selesai';
  static const String revisiHr = 'Revisi HR';
}

class LeaveStatus {
  LeaveStatus._();

  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
}

class PayrollStatus {
  PayrollStatus._();

  static const String pending = 'Pending';
  static const String dibayar = 'Dibayar';
}

class Shifts {
  Shifts._();

  static const String pagi = 'Pagi';
  static const String malam = 'Malam';
  static const String pramuka = 'Pramuka';
  static const String manualHr = 'Manual HR';
}

class Roles {
  Roles._();

  static const String admin = 'Admin';
  static const String hr = 'HR';
  static const String karyawan = 'Karyawan';
}

class DateFormats {
  DateFormats._();

  /// Used as the canonical YYYY-MM-DD key on attendance documents.
  static const String iso = 'yyyy-MM-dd';
  static const String dayShort = 'dd MMM yyyy';
  static const String dayLong = 'EEEE, d MMMM yyyy';
  static const String time = 'HH:mm';
  static const String timeFull = 'HH:mm:ss';
  static const String stamp = 'yyyy-MM-dd HH:mm:ss';
}
