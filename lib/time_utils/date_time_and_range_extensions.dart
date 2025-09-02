

import 'package:flutter/material.dart';

extension ZadartFlutterDateTimeRangeExtensions <T extends DateTime> on DateTimeRange<T> {
  static final _daysExpando = Expando<Iterable<DateTime>>();
  static final _daysListExpando = Expando<List<DateTime>>();

  bool contains(T dt) => !start.isAfter(dt) && !end.isBefore(dt);

  bool containsDays(T dt) =>
      !DateUtils.dateOnly(start).isAfter(DateUtils.dateOnly(dt)) && !DateUtils.dateOnly(end).isBefore(DateUtils.dateOnly(dt));

  bool get isInstant => duration.inMilliseconds == 0;

  Iterable<DateTime> get days {
    if (_daysExpando[this] == null) {
      _daysExpando[this] = iterate(DateUtils.dateOnly, (d) => d.copyWith(day: d.day + 1));
    }
    return _daysExpando[this]!;
  }

  List<DateTime> get daysList {
    if (_daysListExpando[this] == null) {
      return _daysListExpando[this] = days.toList();
    }
    return _daysListExpando[this]!;
  }

  Iterable<DateTime> get months =>
      iterate((d) => DateTime(d.year, d.month), (d) => d.copyWith(month: d.month + 1));

  Iterable<DateTime> iterate(DateTime Function(DateTime) convert, DateTime Function(DateTime) increment) sync* {
    var s = convert(start);
    final e = convert(end);
    while(!s.isAfter(e)) {
      yield s;
      s = increment(s);
    }
  }
}

extension ZadarFlutterDateTimeExtensions <T extends DateTime> on T {
  DateTime clamp({ T? after, T? before }) =>
      switch ((after, before)) {
        (final after?, _) when isBefore(after) => after,
        (_, final before?) when isAfter(before) => before,
        _ => this,
      };

  bool isSameDayAs(DateTime other) => DateUtils.dateOnly(this) == DateUtils.dateOnly(other);

  bool isToday() => isSameDayAs(DateTime.now());
}