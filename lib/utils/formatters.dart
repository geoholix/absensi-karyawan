import 'package:intl/intl.dart';

import 'constants.dart';

/// Formatters reused across the app. Build them once instead of per-build.
class Formatters {
  Formatters._();

  /// Indonesian rupiah, no decimals: "Rp 1.250.000".
  static final NumberFormat currencyIdr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat isoDate = DateFormat(DateFormats.iso);
  static final DateFormat dayShort = DateFormat(DateFormats.dayShort);
  static final DateFormat dayLong = DateFormat(DateFormats.dayLong);
  static final DateFormat time = DateFormat(DateFormats.time);
  static final DateFormat timeFull = DateFormat(DateFormats.timeFull);
  static final DateFormat stamp = DateFormat(DateFormats.stamp);

  /// "yyyy-MM-dd" for the document key on attendance/payroll records.
  static String isoDateKey(DateTime d) => isoDate.format(d);
}
