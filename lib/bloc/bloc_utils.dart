bool Function(S, S) defaultStateHasChanged<S>() => (s1, s2) => s1 != s2;

bool Function(S, S) stateHasChanged<S>({ bool Function(S, S)? stateHasChanged,}) =>
    (S prev, S curr) => (stateHasChanged ?? defaultStateHasChanged())(prev, curr);

bool Function(S, S) selectedStateHasChanged<S, R>(R Function(S) selector, { bool Function(R, R)? stateHasChanged,}) =>
    (S prev, S curr) => (stateHasChanged ?? defaultStateHasChanged())(selector(prev), selector(curr));
