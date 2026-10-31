/// Small text formatting helpers for the UI.
abstract final class Formatters {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// 2026-10-07 -> "Tuesday, 7 Oct"
  static String weekdayDayMonth(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

  /// 42 -> "0:42", 75 -> "1:15"
  static String countdown(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// "Nethmi Perera" -> "NP", "Nethmi" -> "N"
  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// 2418 -> "2,418", -1500 -> "-1,500"
  static String thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// 0.724 -> "72%"
  static String percent(double value) => '${(value * 100).round()}%';

  /// 2026-10-16 -> "16 Oct 2026"
  static String shortDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// "just now", "5 min ago", "3 h ago", "2 d ago", then [shortDate].
  static String relativeTime(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return shortDate(time);
  }

  /// The backend sends unit codes as "6"; older data used "U6".
  /// Both -> "Unit 6". Empty / null -> "".
  static String unitLabel(String? unitCode) {
    final code = (unitCode ?? '').trim();
    if (code.isEmpty) return '';
    final number = code.toUpperCase().startsWith('U')
        ? code.substring(1).trim()
        : code;
    return 'Unit $number';
  }

  /// A wait in seconds as words, rounded up to the minute:
  /// 45 -> "1 minute", 600 -> "10 minutes", 3600 -> "1 hour",
  /// 5400 -> "1 hour 30 minutes", 86400 -> "24 hours".
  static String waitTime(int seconds) {
    final totalMinutes = seconds <= 0 ? 0 : (seconds / 60).ceil();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    String plural(int n, String word) => n == 1 ? '1 $word' : '$n ${word}s';
    if (hours == 0) return plural(minutes < 1 ? 1 : minutes, 'minute');
    if (minutes == 0) return plural(hours, 'hour');
    return '${plural(hours, 'hour')} ${plural(minutes, 'minute')}';
  }

  /// 80 minutes -> "1h 20m", 45 minutes -> "45m"
  static String studyTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}
