// ignore_for_file: avoid_print
import 'package:zadart_flutter/bloc/bloc_utils.dart';

typedef CounterState = ({int count, String label});

/// The bloc helpers build `buildWhen`/`listenWhen`-style change predicates.
/// This example is pure Dart and can be run with `dart run`.
void main() {
  // `defaultStateHasChanged` reports whether the whole state changed (by `==`).
  final changed = defaultStateHasChanged<CounterState>();
  print(changed((count: 1, label: 'a'), (count: 1, label: 'a'))); // false
  print(changed((count: 1, label: 'a'), (count: 2, label: 'a'))); // true

  // `selectedStateHasChanged` only fires when a selected slice changes — ideal
  // for a bloc's `buildWhen` so a widget rebuilds only on the fields it uses.
  final countChanged =
      selectedStateHasChanged<CounterState, int>((s) => s.count);
  print(countChanged((count: 1, label: 'a'), (count: 1, label: 'z'))); // false
  print(countChanged((count: 1, label: 'a'), (count: 2, label: 'a'))); // true
}
