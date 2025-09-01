import 'package:intl/intl.dart';

String formatDateTime(DateTime? date) {
  if (date == null) return "Unknown Date";

  DateFormat formatter = DateFormat("dd MM yyyy");
  return formatter.format(date);
}
