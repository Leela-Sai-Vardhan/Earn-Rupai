import 'package:intl/intl.dart';

/// Utility class for timezone conversions and formatting
/// Converts UTC timestamps to IST (Indian Standard Time, UTC+5:30)
class TimezoneUtils {
  // IST offset from UTC
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  /// Convert UTC DateTime to IST DateTime
  static DateTime toIST(DateTime utcDateTime) {
    return utcDateTime.add(_istOffset);
  }

  /// Format UTC DateTime as IST string
  /// Format: "17 Feb 2026, 06:30 PM"
  static String formatIST(DateTime utcDateTime) {
    final istDateTime = toIST(utcDateTime);
    return DateFormat('dd MMM yyyy, hh:mm a').format(istDateTime);
  }

  /// Format UTC DateTime as IST date only
  /// Format: "17 Feb 2026"
  static String formatISTDate(DateTime utcDateTime) {
    final istDateTime = toIST(utcDateTime);
    return DateFormat('dd MMM yyyy').format(istDateTime);
  }

  /// Format UTC DateTime as IST time only
  /// Format: "06:30 PM"
  static String formatISTTime(DateTime utcDateTime) {
    final istDateTime = toIST(utcDateTime);
    return DateFormat('hh:mm a').format(istDateTime);
  }

  /// Get relative time string (e.g., "2 hours ago", "Just now")
  /// Shows full date if more than 7 days old
  static String relativeTime(DateTime utcDateTime) {
    final istDateTime = toIST(utcDateTime);
    final now = toIST(DateTime.now().toUtc());
    final difference = now.difference(istDateTime);

    if (difference.inDays > 7) {
      return formatIST(utcDateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get short relative time (e.g., "2h ago", "5m ago")
  static String shortRelativeTime(DateTime utcDateTime) {
    final istDateTime = toIST(utcDateTime);
    final now = toIST(DateTime.now().toUtc());
    final difference = now.difference(istDateTime);

    if (difference.inDays > 7) {
      return formatISTDate(utcDateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  /// Format for transaction history
  /// Format: "Today, 06:30 PM" or "Yesterday, 06:30 PM" or "17 Feb, 06:30 PM"
  static String formatTransactionTime(DateTime utcDateTime) {
    final istDateTime = toIST(utcDateTime);
    final now = toIST(DateTime.now().toUtc());
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(istDateTime.year, istDateTime.month, istDateTime.day);

    final timeStr = DateFormat('hh:mm a').format(istDateTime);

    if (transactionDate == today) {
      return 'Today, $timeStr';
    } else if (transactionDate == yesterday) {
      return 'Yesterday, $timeStr';
    } else if (now.difference(istDateTime).inDays < 7) {
      return '${DateFormat('EEEE').format(istDateTime)}, $timeStr';
    } else {
      return '${DateFormat('dd MMM').format(istDateTime)}, $timeStr';
    }
  }
}
