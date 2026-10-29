/// Small text formatting helpers for the UI.
///
import 'package:intl/intl.dart';

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
  static String thousands(num value) =>
      NumberFormat.decimalPattern().format(value);

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

  /// 80 minutes -> "1h 20m", 45 minutes -> "45m"
  static String studyTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}
