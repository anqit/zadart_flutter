/// A change predicate that reports whether two states differ by `==`.
bool Function(S, S) defaultStateHasChanged<S>() => (s1, s2) => s1 != s2;

/// A change predicate over states of type [S], using [stateHasChanged] if given
/// and `==` otherwise. Suitable for a bloc's `buildWhen`/`listenWhen`.
bool Function(S, S) stateHasChanged<S>({ bool Function(S, S)? stateHasChanged,}) =>
    (S prev, S curr) => (stateHasChanged ?? defaultStateHasChanged())(prev, curr);

/// A change predicate that compares only the [selector]ed slice of the state,
/// using [stateHasChanged] on that slice if given and `==` otherwise.
bool Function(S, S) selectedStateHasChanged<S, R>(R Function(S) selector, { bool Function(R, R)? stateHasChanged,}) =>
    (S prev, S curr) => (stateHasChanged ?? defaultStateHasChanged())(selector(prev), selector(curr));
