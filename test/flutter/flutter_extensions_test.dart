import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zadart_flutter/zadart_flutter.dart';

void main() {
  group('expandWrapped', () {
    testWidgets('wraps each widget in an iterable in Expanded', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: _Row([Text('a'), Text('b'), Text('c')]),
        ),
      ));
      expect(find.byType(Expanded), findsNWidgets(3));
    });

    testWidgets('wraps a single widget in Expanded', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: _SingleRow(Text('x'))),
      ));
      expect(find.byType(Expanded), findsOneWidget);
    });
  });

  group('showSnackbar', () {
    testWidgets('displays the given message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSnackbar(context, 'Hi there'),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pump(); // let the snackbar animate in
      expect(find.text('Hi there'), findsOneWidget);
    });
  });
}

class _Row extends StatelessWidget {
  final List<Widget> children;
  const _Row(this.children);

  @override
  Widget build(BuildContext context) => Row(children: children.expandWrapped());
}

class _SingleRow extends StatelessWidget {
  final Widget child;
  const _SingleRow(this.child);

  @override
  Widget build(BuildContext context) => Row(children: [child.expandWrapped()]);
}
