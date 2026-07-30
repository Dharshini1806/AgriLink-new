import 'package:intl/intl.dart';

class AppFormatters {
  static final _rupee    = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final _compact  = NumberFormat.compact(locale: 'en_IN');
  static final _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final _date     = DateFormat('d MMM yyyy');
  static final _time     = DateFormat('h:mm a');

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String currency(double amount) => _rupee.format(amount);
  static String compact(num value)      => _compact.format(value);
  static String dateTime(DateTime dt)   => _dateTime.format(dt.toLocal());
  static String date(DateTime dt)       => _date.format(dt.toLocal());
  static String time(DateTime dt)       => _time.format(dt.toLocal());

  static String distance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

  static String qualityGrade(String? grade) {
    switch (grade) {
      case 'A': return '⭐ Premium (A)';
      case 'B': return '✓ Standard (B)';
      case 'C': return '● Economy (C)';
      default:  return grade ?? '';
    }
  }

  static String orderStatus(String status) {
    const map = {
      'pending':          'Pending',
      'confirmed':        'Confirmed',
      'packed':           'Packed',
      'out_for_delivery': 'Out for Delivery',
      'delivered':        'Delivered',
      'cancelled':        'Cancelled',
    };
    return map[status] ?? status;
  }
}
