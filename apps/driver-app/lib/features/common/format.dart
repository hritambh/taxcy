/// ₹ with Indian digit grouping: 12345678 paise → "₹1,23,456.78"; whole rupees drop ".00".
String formatInr(int paise) {
  final negative = paise < 0;
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final cents = abs % 100;
  final digits = rupees.toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  final fraction = cents == 0 ? '' : '.${cents.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}₹$grouped$fraction';
}

/// "₹1,234.50" → 123450 paise; null when not a valid non-negative amount.
int? parseRupees(String input) {
  final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0 || !value.isFinite) return null;
  return (value * 100).round();
}

const _months = [
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

String formatTime(DateTime at) {
  final local = at.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m ${local.hour < 12 ? 'am' : 'pm'}';
}

String formatDay(DateTime at, {DateTime? now}) {
  final local = at.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final diff = day
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  return '${local.day} ${_months[local.month - 1]}';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

const statusLabels = {
  'created': 'Not assigned',
  'assigned': 'Assigned',
  'started': 'On the road',
  'ended': 'Ended',
  'settled': 'Settled',
  'cancelled': 'Cancelled',
};

const chargeKindLabels = {
  'toll': 'Toll',
  'parking': 'Parking',
  'state_tax': 'State tax',
  'driver_allowance': 'Driver allowance',
  'night_charge': 'Night charge',
  'extra_km': 'Extra km',
  'other': 'Other',
};
