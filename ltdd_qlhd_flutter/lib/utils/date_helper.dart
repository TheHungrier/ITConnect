class DateHelper {
  static String getDay(DateTime date) {
    return date.day.toString().padLeft(2, '0');
  }

  static String getMonth(DateTime date) {
    return 'TH${date.month}';
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  static String formatTimeRange(DateTime startAt, DateTime endAt) {
    return '${formatTime(startAt)} - ${formatTime(endAt)}';
  }

  static String formatNullableDate(DateTime? date) {
    if (date == null) return 'Chưa rõ ngày';
    return formatDate(date);
  }

  static String getNullableDay(DateTime? date) {
    if (date == null) return '--';
    return getDay(date);
  }

  static String getNullableMonth(DateTime? date) {
    if (date == null) return '--';
    return getMonth(date);
  }
}
