import 'package:flutter/widgets.dart';
import 'package:zadart/zadart.dart';

extension ZadartFlutterWidgetIterableExtensions on Iterable<Widget> {
  List<Widget> expandWrapped() =>
      map((e) => Expanded(child: e)).toList();
}

extension ZadartFlutterWidgetExtensions on Widget {
  Widget expandWrapped() =>
      Expanded(child: this);
}

extension ZadartFlutterStateExtensions<T extends StatefulWidget> on State<T> {
  // I don't think this is invalid
  // ignore: invalid_use_of_protected_member
  void refreshState() => setState(noop);
}
