import 'package:flutter/material.dart';
import 'package:zadart_flutter/zadart_flutter.dart';

/// Wrap widgets in `Expanded` without the nesting boilerplate.
Widget rowOfExpanded(Widget a, Widget b, Widget c) =>
    Row(children: [a, b, c].expandWrapped());

Widget singleExpanded(Widget child) =>
    Row(children: [child.expandWrapped()]);

/// Show a snackbar (hides the current one first by default).
void onSaved(BuildContext context) {
  showSnackbar(context, 'Saved!');
  showSnackbar(context, 'Queued', hideCurrent: false); // stack instead
}

/// `State` extensions: force a rebuild, or guard `setState` on `mounted`.
class Ticker extends StatefulWidget {
  const Ticker({super.key});

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  int _ticks = 0;

  void refreshAfterExternalChange() => refreshState(); // setState(noop)

  void bumpLater() {
    Future.delayed(const Duration(seconds: 1), () {
      // Skips setState if the widget was disposed in the meantime.
      setStateMounted(() => _ticks++);
    });
  }

  @override
  Widget build(BuildContext context) => Text('$_ticks');
}
