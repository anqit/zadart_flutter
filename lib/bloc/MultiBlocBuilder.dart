import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class HList {
  static NonEmptyHList<H, HNil> call<H>(H h) => NonEmptyHList(h, HNil._instance);
  List<dynamic> get toList;
}

final class HNil extends HList {
  HNil._();
  static final HNil _instance = HNil._();

  factory HNil() => _instance;

  @override
  List<dynamic> get toList => const [];

  NonEmptyHList<H, HNil> prepend<H>(H head) => NonEmptyHList(head, this);
}

final class NonEmptyHList<Head, Tail extends HList> extends HList {
  final Head head;
  final Tail tail;

  NonEmptyHList(this.head, this.tail);

  @override
  List<dynamic> get toList => [ head, ...tail.toList, ];

  NonEmptyHList<H, NonEmptyHList<Head, Tail>> prepend<H>(H h) => NonEmptyHList(h, this);
}

extension HListExtensions<H> on H {
  NonEmptyHList<H, HNil> hlist() => NonEmptyHList(this, HNil());
  NonEmptyHList<H, Tail> prependTo<Tail extends HList>(Tail tail) => NonEmptyHList(this, tail);
}

void testThings() {
  final list = 1.hlist();
  final again = "hi".prependTo(list);
}

sealed class HListOf<R> extends HList {
  @override
  List<R> get toList;
}
class NonEmptyHListOf<R, /*H extends R, */ Tail extends HListOf<R>> extends HListOf<R> {
  final R head;
  final Tail tail;

  NonEmptyHListOf(this.head, this.tail);

  @override
  List<R> get toList => [ head, ...tail.toList ];
}

typedef BlocPair<State, B extends Bloc<dynamic, State>> = (Bloc, State);

class MultiBlocBuilder<Blocs extends HListOf<Bloc>> extends StatelessWidget {
  Blocs blocs;
  Widget Function(BuildContext, Blocs) builder;

  MultiBlocBuilder({ required this.blocs, required this.builder });

  @override
  Widget build(BuildContext context) {

  }

  Widget _build(BuildContext ctx, HList bs) {
    switch(bs) {
      NonEmptyHList(head, tail) => 
    }
  }
}

class b1 extends Bloc<String, int> {}
class b2 extends Bloc<String, int> {}

final mb = MultiBlocBuilder(
  blocs: (b1, b2),
  builder: (ctx, s1, s2) => Text('$s1 + $s2 = ${s1 + s2}');
);
