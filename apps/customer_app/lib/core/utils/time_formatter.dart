/// Compact "3m ago" / "2d ago" style relative timestamps for notification
/// and chat feeds, where a full date is more clutter than signal.
String formatRelativeTime(DateTime value) {
  final Duration diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${value.day}/${value.month}/${value.year}';
}
