import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Chưa có';
    }

    return _dateTimeFormat.format(dateTime);
  }
}
