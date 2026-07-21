import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zadart_flutter/zadart_flutter.dart';

void main() {
  group('DateTimeRange', () {
    final range = DateTimeRange(
      start: DateTime(2026, 1, 30, 8),
      end: DateTime(2026, 2, 2, 20),
    );

    test('days yields each date-only day in the range', () {
      expect(range.days.toList(), [
        DateTime(2026, 1, 30),
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 2),
      ]);
    });

    test('months yields the first-of-month for each month spanned', () {
      expect(range.months.toList(), [DateTime(2026, 1), DateTime(2026, 2)]);
    });

    test('contains is inclusive of the endpoints', () {
      expect(range.contains(DateTime(2026, 1, 31)), isTrue);
      expect(range.contains(DateTime(2026, 1, 30, 8)), isTrue); // start
      expect(range.contains(DateTime(2026, 2, 3)), isFalse);
    });

    test('isInstant is true only for a zero-duration range', () {
      final t = DateTime(2026, 1, 1);
      expect(DateTimeRange(start: t, end: t).isInstant, isTrue);
      expect(range.isInstant, isFalse);
    });
  });

  group('DateTime', () {
    test('clamp bounds the value between after and before', () {
      final dt = DateTime(2026, 6, 15);
      expect(dt.clamp(after: DateTime(2026, 7, 1)), DateTime(2026, 7, 1));
      expect(dt.clamp(before: DateTime(2026, 1, 1)), DateTime(2026, 1, 1));
      expect(
        dt.clamp(after: DateTime(2026, 1, 1), before: DateTime(2026, 12, 31)),
        dt,
      );
    });

    test('isSameDayAs ignores the time of day', () {
      expect(
        DateTime(2026, 1, 30, 1).isSameDayAs(DateTime(2026, 1, 30, 23)),
        isTrue,
      );
      expect(
        DateTime(2026, 1, 30).isSameDayAs(DateTime(2026, 1, 31)),
        isFalse,
      );
    });

    test('withTime replaces the time, keeping the date', () {
      final dt = DateTime(2026, 1, 30, 14, 5);
      expect(
        dt.withTime(const TimeOfDay(hour: 9, minute: 0)),
        DateTime(2026, 1, 30, 9, 0),
      );
      expect(dt.withTime(null), dt);
    });

    test('time returns the time of day', () {
      expect(
        DateTime(2026, 1, 30, 14, 5).time,
        const TimeOfDay(hour: 14, minute: 5),
      );
    });
  });
}
