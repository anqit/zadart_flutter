import 'package:flutter/material.dart';
import 'package:zadart/zadart.dart';

/// Extensions on [DateTimeRange].
extension ZadartFlutterDateTimeRangeExtensions <T extends DateTime> on DateTimeRange<T> {
  static final _daysExpando = Expando<Iterable<DateTime>>();
  static final _daysListExpando = Expando<List<DateTime>>();

  /// Whether [dt] falls within this range, inclusive of both endpoints.
  bool contains(T dt) => !start.isAfter(dt) && !end.isBefore(dt);

  /// Whether [dt]'s date falls within this range, comparing dates only.
  bool containsDays(T dt) =>
      !DateUtils.dateOnly(start).isAfter(DateUtils.dateOnly(dt)) && !DateUtils.dateOnly(end).isBefore(DateUtils.dateOnly(dt));

  /// Whether this range has zero duration.
  bool get isInstant => duration.inMilliseconds == 0;

  /// Each date-only day spanned by this range.
  Iterable<DateTime> get days {
    if (_daysExpando[this] == null) {
      _daysExpando[this] = iterate(DateUtils.dateOnly, (d) => d.copyWith(day: d.day + 1));
    }
    return _daysExpando[this]!;
  }

  /// [days] as a materialized, cached list.
  List<DateTime> get daysList {
    if (_daysListExpando[this] == null) {
      return _daysListExpando[this] = days.toList();
    }
    return _daysListExpando[this]!;
  }

  /// The first-of-month for each month spanned by this range.
  Iterable<DateTime> get months =>
      iterate((d) => DateTime(d.year, d.month), (d) => d.copyWith(month: d.month + 1));

  /// Yields values from the start to the end of this range, projecting each end
  /// with [convert] and stepping with [increment].
  Iterable<DateTime> iterate(DateTime Function(DateTime) convert, DateTime Function(DateTime) increment) sync* {
    var s = convert(start);
    final e = convert(end);
    while(!s.isAfter(e)) {
      yield s;
      s = increment(s);
    }
  }
}

/// Extensions on [DateTime].
extension ZadartFlutterDateTimeExtensions <T extends DateTime> on T {
  /// This value clamped to be no earlier than [after] and no later than
  /// [before] (each optional).
  DateTime clamp({ T? after, T? before }) =>
      switch ((after, before)) {
        (final after?, _) when isBefore(after) => after,
        (_, final before?) when isAfter(before) => before,
        _ => this,
      };

  /// Whether this and [other] fall on the same calendar day.
  bool isSameDayAs(DateTime other) => DateUtils.dateOnly(this) == DateUtils.dateOnly(other);

  /// Whether this falls on today's date.
  bool isToday() => isSameDayAs(DateTime.now());

  /// This value's time of day.
  TimeOfDay get time => TimeOfDay.fromDateTime(this);

  /// This value with its time replaced by [time], or unchanged if [time] is null.
  DateTime withTime(TimeOfDay? time) => time.map((t) => copyWith(hour: t.hour, minute: t.minute)) ?? this;
}
