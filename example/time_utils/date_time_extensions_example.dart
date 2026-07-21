import 'package:flutter/material.dart';
import 'package:zadart_flutter/zadart_flutter.dart';

/// Extensions on [DateTimeRange] and [DateTime]. (Illustrative snippet —
/// compile-checked; the `intl`/material types make it a Flutter example.)
void dateExamples() {
  final range = DateTimeRange(
    start: DateTime(2026, 1, 30),
    end: DateTime(2026, 2, 2),
  );

  // Every day spanned by the range (lazily iterated, date-only).
  for (final day in range.days) {
    debugPrint('$day'); // 2026-01-30, 01-31, 02-01, 02-02
  }

  // First-of-month for each month the range touches.
  range.months; // [2026-01-01, 2026-02-01]

  // Inclusive containment.
  range.contains(DateTime(2026, 1, 31)); // true

  final dt = DateTime(2026, 1, 30, 14, 5);

  dt.isToday();
  dt.isSameDayAs(DateTime(2026, 1, 30, 23, 0)); // true

  // Clamp within an optional lower/upper bound.
  dt.clamp(after: DateTime(2026, 1, 1), before: DateTime(2026, 12, 31));

  // Replace the time-of-day, keeping the date.
  dt.withTime(const TimeOfDay(hour: 9, minute: 0));

  // Read the time-of-day.
  dt.time; // TimeOfDay(14:05)
}
