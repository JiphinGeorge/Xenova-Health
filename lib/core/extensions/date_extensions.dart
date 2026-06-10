import 'package:intl/intl.dart';

/// DateTime extensions for Xenova Health.
extension DateTimeExtensions on DateTime {
  /// Returns date-only (midnight) version of this DateTime.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns true if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns true if this date is in the current week.
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.dateOnly.subtract(const Duration(seconds: 1))) &&
        isBefore(endOfWeek.dateOnly.add(const Duration(days: 1)));
  }

  /// Returns true if this date is in the current month.
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Formats as short date (e.g., "Jun 10").
  String get formatShort => DateFormat('MMM d').format(this);

  /// Formats as medium date (e.g., "Jun 10, 2026").
  String get formatMedium => DateFormat('MMM d, yyyy').format(this);

  /// Formats as long date (e.g., "June 10, 2026").
  String get formatLong => DateFormat('MMMM d, yyyy').format(this);

  /// Formats as full date (e.g., "Wednesday, June 10, 2026").
  String get formatFull => DateFormat('EEEE, MMMM d, yyyy').format(this);

  /// Formats as time (e.g., "10:30 PM").
  String get formatTime => DateFormat('h:mm a').format(this);

  /// Formats as date + time (e.g., "Jun 10, 2026 10:30 PM").
  String get formatDateTime => DateFormat('MMM d, yyyy h:mm a').format(this);

  /// Formats as Firestore-compatible date key (e.g., "2026-06-10").
  String get toDateKey => DateFormat('yyyy-MM-dd').format(this);

  /// Returns a relative time string (e.g., "2 hours ago", "Yesterday").
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Returns the number of days between this date and [other].
  int daysBetween(DateTime other) {
    return dateOnly.difference(other.dateOnly).inDays.abs();
  }

  /// Returns the start of the current week (Monday).
  DateTime get startOfWeek => subtract(Duration(days: weekday - 1)).dateOnly;

  /// Returns the end of the current week (Sunday).
  DateTime get endOfWeek => add(Duration(days: 7 - weekday)).dateOnly;

  /// Returns the start of the current month.
  DateTime get startOfMonth => DateTime(year, month);

  /// Returns the end of the current month.
  DateTime get endOfMonth => DateTime(year, month + 1, 0);
}
