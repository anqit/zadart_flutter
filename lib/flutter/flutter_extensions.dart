import 'package:flutter/widgets.dart';
import 'package:zadart/zadart.dart';

/// Extensions on an iterable of widgets.
extension ZadartFlutterWidgetIterableExtensions on Iterable<Widget> {
  /// Wraps each widget in an [Expanded].
  List<Widget> expandWrapped() =>
      map((e) => Expanded(child: e)).toList();
}

/// Extensions on a single [Widget].
extension ZadartFlutterWidgetExtensions on Widget {
  /// Wraps this widget in an [Expanded].
  Widget expandWrapped() =>
      Expanded(child: this);
}

/// Extensions on [State].
extension ZadartFlutterStateExtensions<T extends StatefulWidget> on State<T> {
  /// Calls `setState` with no changes to force a rebuild.
  void refreshState() {
    // ignore: invalid_use_of_protected_member
    setState(noop);
  }

  /// Calls `setState` with [callback] only if this [State] is still mounted.
  void setStateMounted(VoidCallback callback) {
    // ignore: invalid_use_of_protected_member
    if (mounted) setState(callback);
  }
}
