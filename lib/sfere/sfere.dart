import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zadart/zadart.dart';

typedef SfereStateKeyed<K, T> = Map<K, T>;
typedef SfereState<T> = Iterable<T>;

extension <K, T> on SfereStateKeyed<K, T> {
  SfereState<T> get _sfereState => values;
}

typedef SfereStateCompareKeyed<K, T> = bool Function(SfereStateKeyed<K, T>, SfereStateKeyed<K, T>);
typedef SfereStateCompare<T> = bool Function(SfereState<T>, SfereState<T>);

extension <T> on SfereStateCompare<T> {
  SfereStateCompareKeyed<K, T> _toCompareKeyed<K>() => (sk1, sk2) => this(sk1._sfereState, sk2._sfereState);
  SfereStateCompareKeyed<Object, T> get _keyed => _toCompareKeyed();
}

typedef SfereStateBuilderKeyed<K, T> = Widget Function(BuildContext, SfereStateKeyed<K, T>);
typedef SfereStateBuilder<T> = Widget Function(BuildContext, SfereState<T>);

extension <T> on SfereStateBuilder<T> {
  SfereStateBuilderKeyed<K, T> _toBuilderKeyed<K>() => (ctx, sk) => this(ctx, sk._sfereState);
  SfereStateBuilderKeyed<Object, T> get _keyed => _toBuilderKeyed();
}

typedef SfereStateListenerKeyed<K, T> = void Function(BuildContext, SfereStateKeyed<K, T>);
typedef SfereStateListener<T> = void Function(BuildContext, SfereState<T>);

extension <T> on SfereStateListener<T> {
  SfereStateListenerKeyed<K, T> _toListenerKeyed<K>() => (ctx, sk) => this(ctx, sk._sfereState);
  SfereStateListenerKeyed<Object, T> get _keyed => _toListenerKeyed();
}

typedef SfereStateSelectorKeyed<K, T, V> = V Function(SfereStateKeyed<K, T>);
typedef SfereStateSelector<T, V> = V Function(SfereState<T>);

extension <T, V> on SfereStateSelector<T, V> {
  SfereStateSelectorKeyed<K, T, V> _toSelectorKeyed<K>() => (sk) => this(sk._sfereState);
  SfereStateSelectorKeyed<Object, T, V> get _keyed => _toSelectorKeyed();
}

class _SfereTracker<K, T> extends Cubit<SfereStateKeyed<K, T>> {
  _SfereTracker() : super(const {});

  void _update(K key, T value) => emit(state.updated(key, value));

  void _remove(K key) => emit(state.without(key));
}

abstract class _SfereValueCubit<V> extends Cubit<V> {
  _SfereValueCubit(super.initial);
}

class _SfereValueTracker<K, T, V> extends _SfereValueCubit<V> {
  late final StreamSubscription<SfereStateKeyed<K, T>> _sub;

  _SfereValueTracker({
    required _SfereTracker<K, T> tracker,
    required SfereStateSelectorKeyed<K, T, V> selector,
  }) : super(selector(tracker.state)) {
    _sub = tracker.stream.listen((sk) => emit(selector(sk)));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

class CustomSfereKeyed<K, T> extends StatelessWidget {
  final Widget child;

  const CustomSfereKeyed({ super.key, required this.child });

  CustomSfereKeyed.builder({
    super.key,
    required SfereStateBuilderKeyed<K, T> builder,
    SfereStateCompareKeyed<K, T>? buildWhen,
    SfereStateListenerKeyed<K, T>? listener,
    SfereStateCompareKeyed<K, T>? listenWhen,
  }) : child = CustomSfereBuilderKeyed<K, T>(
    builder: builder,
    buildWhen: buildWhen,
    listener: listener,
    listenWhen: listenWhen,
  );

  @override
  Widget build(BuildContext context) =>
      BlocProvider<_SfereTracker<K, T>>(
        create: (_) => _SfereTracker(),
        child: child,
      );
}

class CustomSfere<T> extends CustomSfereKeyed<Object, T> {
  const CustomSfere({ super.key, required super.child });

  CustomSfere.builder({
    super.key,
    required SfereStateBuilder<T> builder,
    SfereStateCompare<T>? buildWhen,
    SfereStateListener<T>? listener,
    SfereStateCompare<T>? listenWhen,
  }) : super(child: CustomSfereBuilder<T>(
    builder: builder,
    buildWhen: buildWhen,
    listener: listener,
    listenWhen: listenWhen,
  ));
}

class SfereKeyed<K, T, V> extends StatelessWidget {
  final Widget child;
  final SfereStateSelectorKeyed<K, T, V> selector;

  const SfereKeyed({
    super.key,
    required this.selector,
    required this.child,
  });

  SfereKeyed.builder({
    super.key,
    required this.selector,
    required Widget Function(BuildContext, V) builder,
    bool Function(V, V)? buildWhen,
    void Function(BuildContext, V)? listener,
    bool Function(V, V)? listenWhen,
  }) : child = SfereBuilder<V>(
    builder: builder,
    buildWhen: buildWhen,
    listener: listener,
    listenWhen: listenWhen,
  );

  @override
  Widget build(BuildContext context) =>
      MultiBlocProvider(
        providers: [
          BlocProvider<_SfereTracker<K, T>>(create: (_) => _SfereTracker()),
          BlocProvider<_SfereValueCubit<V>>(
            create: (ctx) => _SfereValueTracker<K, T, V>(
              tracker: ctx.read<_SfereTracker<K, T>>(),
              selector: selector,
            ),
          ),
        ],
        child: child,
      );
}

class Sfere<T, V> extends SfereKeyed<Object, T, V> {
  Sfere({
    super.key,
    required SfereStateSelector<T, V> selector,
    required super.child,
  }) : super(selector: selector._keyed);

  Sfere.builder({
    super.key,
    required SfereStateSelector<T, V> selector,
    required super.builder,
    super.buildWhen,
    super.listener,
    super.listenWhen,
  }) : super.builder(selector: selector._keyed,);
}

class SferePointKeyed<K, T> extends StatefulWidget {
  final K? id;
  final T value;
  final Widget child;

  const SferePointKeyed({
    super.key,
    required this.id,
    required this.value,
    required this.child,
  });

  static SferePointKeyed<K, T> builder<K, T, V>({
    Key? key,
    required K id,
    required T value,
    required Widget Function(BuildContext, V) builder,
    bool Function(V, V)? buildWhen,
    void Function(BuildContext, V)? listener,
    bool Function(V, V)? listenWhen,
  }) => SferePointKeyed<K, T>(
    key: key,
    id: id,
    value: value,
    child: SfereBuilder<V>(
      builder: builder,
      buildWhen: buildWhen,
      listener: listener,
      listenWhen: listenWhen,
    ),
  );

  @override
  State<SferePointKeyed<K, T>> createState() => _SferePointState<K, T>();
}

class _SferePointState<K, T> extends State<SferePointKeyed<K, T>> {
  _SfereTracker<K, T>? _sfere;

  K _id([SferePointKeyed<K, T>? w]) => ((w ?? widget).id ?? this) as K;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSfere = BlocProvider.of<_SfereTracker<K, T>>(context, listen: true);
    if (_sfere != newSfere) {
      final originalId = _id();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _sfere?._remove(originalId);
          _sfere = newSfere;
          _sync();
        }
      });
    }
  }

  @override
  void didUpdateWidget(SferePointKeyed<K, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = _id(oldWidget);
    if (oldId != _id() || oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (oldId != _id()) _sfere?._remove(oldId);
          _sync();
        }
      });
    }
  }

  @override
  void dispose() {
    _sfere.filter((s) => !s.isClosed).ifNotNull((s) => s._remove(_id()));
    super.dispose();
  }

  void _sync() => _sfere?._update(_id(), widget.value);

  @override
  Widget build(BuildContext context) => widget.child;
}

class SferePoint<T> extends SferePointKeyed<Object, T> {
  const SferePoint({
    super.key,
    required super.value,
    required super.child,
  }) : super(id: null);

  static SferePoint<T> builder<T, V>({
    Key? key,
    required T value,
    required Widget Function(BuildContext, V) builder,
    bool Function(V, V)? buildWhen,
    void Function(BuildContext, V)? listener,
    bool Function(V, V)? listenWhen,
  }) => SferePoint<T>(
    key: key,
    value: value,
    child: SfereBuilder<V>(
      builder: builder,
      buildWhen: buildWhen,
      listener: listener,
      listenWhen: listenWhen,
    ),
  );
}

class CustomSfereBuilderKeyed<K, T> extends StatelessWidget {
  final SfereStateBuilderKeyed<K, T> builder;
  final SfereStateCompareKeyed<K, T>? buildWhen;
  final SfereStateListenerKeyed<K, T>? listener;
  final SfereStateCompareKeyed<K, T>? listenWhen;

  const CustomSfereBuilderKeyed({
    super.key,
    required this.builder,
    this.buildWhen,
    this.listener,
    this.listenWhen,
  });

  @override
  Widget build(BuildContext context) =>
      listener.map((l) =>
          BlocConsumer<_SfereTracker<K, T>, SfereStateKeyed<K, T>>(
            buildWhen: buildWhen,
            listenWhen: listenWhen,
            listener: l,
            builder: builder,
          )
      ) ?? BlocBuilder<_SfereTracker<K, T>, SfereStateKeyed<K, T>>(
        buildWhen: buildWhen,
        builder: builder,
      );
}

class CustomSfereBuilder<T> extends CustomSfereBuilderKeyed<Object, T> {
  CustomSfereBuilder({
    super.key,
    required SfereStateBuilder<T> builder,
    SfereStateCompare<T>? buildWhen,
    SfereStateListener<T>? listener,
    SfereStateCompare<T>? listenWhen,
  }) : super(
    builder: builder._keyed,
    buildWhen: buildWhen?._keyed,
    listener: listener?._keyed,
    listenWhen: listenWhen?._keyed,
  );
}

class SfereBuilder<V> extends StatelessWidget {
  final Widget Function(BuildContext, V) builder;
  final bool Function(V, V)? buildWhen;
  final void Function(BuildContext, V)? listener;
  final bool Function(V, V)? listenWhen;

  const SfereBuilder({
    super.key,
    required this.builder,
    this.buildWhen,
    this.listener,
    this.listenWhen,
  });

  @override
  Widget build(BuildContext context) =>
      listener.map((l) =>
          BlocConsumer<_SfereValueCubit<V>, V>(
            buildWhen: buildWhen,
            listenWhen: listenWhen,
            listener: l,
            builder: builder,
          )
      ) ?? BlocBuilder<_SfereValueCubit<V>, V>(
        buildWhen: buildWhen,
        builder: builder,
      );
}

class CustomSfereSelectorKeyed<K, T, V> extends StatelessWidget {
  final Widget Function(BuildContext, V) builder;
  final SfereStateSelectorKeyed<K, T, V> selector;
  final void Function(BuildContext, V)? listener;
  final bool Function(V, V)? listenWhen;

  const CustomSfereSelectorKeyed({
    super.key,
    required this.builder,
    required this.selector,
    this.listener,
    this.listenWhen,
  });

  @override
  Widget build(BuildContext context) {
    final selectorWidget = BlocSelector<_SfereTracker<K, T>, SfereStateKeyed<K, T>, V>(
      selector: selector,
      builder: builder,
    );
    return listener.map((l) =>
        BlocListener<_SfereTracker<K, T>, SfereStateKeyed<K, T>>(
          listenWhen: listenWhen.map((lw) => (prev, curr) => lw(selector(prev), selector(curr))),
          listener: (ctx, state) => l(ctx, selector(state)),
          child: selectorWidget,
        )
    ) ?? selectorWidget;
  }
}

class CustomSfereSelector<T, V> extends CustomSfereSelectorKeyed<Object, T, V> {
  CustomSfereSelector({
    super.key,
    required super.builder,
    required SfereStateSelector<T, V> selector,
    super.listener,
    super.listenWhen,
  }) : super(selector: selector._keyed);
}

class SfereSelector<V, W> extends StatelessWidget {
  final Widget Function(BuildContext, W) builder;
  final W Function(V) selector;
  final void Function(BuildContext, W)? listener;
  final bool Function(W, W)? listenWhen;

  const SfereSelector({
    super.key,
    required this.builder,
    required this.selector,
    this.listener,
    this.listenWhen,
  });

  @override
  Widget build(BuildContext context) {
    final selectorWidget = BlocSelector<_SfereValueCubit<V>, V, W>(
      selector: selector,
      builder: builder,
    );
    return listener.map((l) =>
        BlocListener<_SfereValueCubit<V>, V>(
          listenWhen: listenWhen.map((lw) => (prev, curr) => lw(selector(prev), selector(curr))),
          listener: (ctx, state) => l(ctx, selector(state)),
          child: selectorWidget,
        )
    ) ?? selectorWidget;
  }
}
