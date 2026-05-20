import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zadart/zadart.dart';

typedef SfereWidgetBuilder<T> = Widget Function(BuildContext, Iterable<T>);
typedef SfereWidgetBuilderKeyed<K, T> = Widget Function(BuildContext, Map<K, T>);

extension <T> on SfereWidgetBuilder<T> {
  SfereWidgetBuilderKeyed<K, T> _toBuilderKeyed<K>() => (ctx, state) => this(ctx, state.values);
}

class _SfereCubit<K, T> extends Cubit<Map<K, T>> {
  _SfereCubit() : super(const {});

  void _update(K key, T value) {
    if (!state.containsKey(key) || state[key] != value) {
      emit(state.updated(key, value));
    }
  }

  void _remove(K key) {
    if (state.containsKey(key)) {
      emit(state.without(key));
    }
  }
}

class _Sfere<K, T> extends StatelessWidget {
  final Widget child;

  const _Sfere({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) =>
      BlocProvider<_SfereCubit<K, T>>(
        create: (_) => _SfereCubit(),
        child: child,
      );
}

class Sfere<T> extends _Sfere<Object, T> {
  const Sfere({ super.key, required super.child });
}

class SfereKeyed<K, T> extends _Sfere<K, T> {
  const SfereKeyed({ super.key, required super.child });
}

class _SferePoint<K, T> extends StatefulWidget {
  final K? id;
  final T value;
  final SfereWidgetBuilderKeyed<K, T>? builder;
  final Widget? child;

  const _SferePoint({
    super.key,
    required this.value,
    this.id,
    this.builder,
    this.child,
  }) : assert(child != null || builder != null, 'SferePoint requires child or builder');

  @override
  _SferePointState<K, T> createState() => _SferePointState<K, T>();
}

class _SferePointState<K, T> extends State<_SferePoint<K, T>> {
  _SfereCubit<K, T>? _sfere;

  K _id([_SferePoint<K, T>? w]) => ((w ?? widget).id ?? this) as K;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newSfere = BlocProvider.of<_SfereCubit<K, T>>(context, listen: true);
    if (_sfere != newSfere) {
      final _originalId = _id();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _sfere?._remove(_originalId);
          _sfere = newSfere;
          _sync();
        }
      });
    }
  }

  @override
  void didUpdateWidget(_SferePoint<K, T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = _id(oldWidget);
    if (oldId != _id() || oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (oldId != _id()) {
            _sfere?._remove(oldId);
          }
          _sync();
        }
      });
    }
  }

  @override
  void dispose() {
    if (_sfere != null && !_sfere!.isClosed) {
        _sfere!._remove(_id());
    }
    super.dispose();
  }

  void _sync() => _sfere?._update(_id(), widget.value);

  @override
  Widget build(BuildContext context) =>
      widget.child ??
          BlocBuilder<_SfereCubit<K, T>, Map<K, T>>(
            builder: (ctx, state) => widget.builder!(ctx, state),
          );
}

class SferePoint<T> extends _SferePoint<Object, T> {
  const SferePoint({
    super.key,
    required super.value,
    required Widget child,
  }) : super(child: child);

  SferePoint.builder({
    super.key,
    required super.value,
    required SfereWidgetBuilder<T> builder,
  }) : super(builder: builder._toBuilderKeyed());
}

class SferePointKeyed<K, T> extends _SferePoint<K, T> {
  const SferePointKeyed({
    super.key,
    required super.id,
    required super.value,
    required Widget child,
  }) : super(child: child);

  const SferePointKeyed.builder({
    super.key,
    required super.id,
    required super.value,
    required super.builder,
  });
}

class _SfereBuilder<K, T> extends StatelessWidget {
  final Widget Function(BuildContext, Map<K, T>) builder;

  const _SfereBuilder({ super.key, required this.builder });

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<_SfereCubit<K, T>, Map<K, T>>(
        builder: builder,
      );
}

class SfereBuilder<T> extends _SfereBuilder<Object, T> {
  SfereBuilder({
    super.key,
    required SfereWidgetBuilder<T> builder,
  }) : super(builder: builder._toBuilderKeyed());
}

class SfereBuilderKeyed<K, T> extends _SfereBuilder<K, T> {
  const SfereBuilderKeyed({
    super.key,
    required super.builder,
  });
}

class _SfereSelector<K, T, V> extends StatelessWidget {
  final Widget Function(BuildContext, V) builder;
  final V Function(Map<K, T>) selector;

  const _SfereSelector({ super.key, required this.builder, required this.selector });

  @override
  Widget build(BuildContext context) =>
      BlocSelector<_SfereCubit<K, T>, Map<K, T>, V>(
        selector: selector,
        builder: builder,
      );
}

class SfereSelector<T, V> extends _SfereSelector<Object, T, V> {
  SfereSelector({
    super.key,
    required super.builder,
    required V Function(Iterable<T>) selector,
  }) : super(selector: (state) => selector(state.values));
}

class SfereSelectorKeyed<K, T, V> extends _SfereSelector<K, T, V> {
  const SfereSelectorKeyed({
    super.key,
    required super.builder,
    required super.selector,
  });
}
