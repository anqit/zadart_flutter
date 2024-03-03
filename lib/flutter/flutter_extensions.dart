import 'package:flutter/material.dart';

extension WidgetIterableExtensions on Iterable<Widget> {
  List<Widget> expandWrapped() =>
      map((e) => Expanded(child: e)).toList();
}

extension WidgetExtensions on Widget {
  Widget expandWrapped() =>
      Expanded(child: this);
}
