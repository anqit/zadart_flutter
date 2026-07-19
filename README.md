# zadart_flutter

Flutter companion to the [`zadart`](https://pub.dev/packages/zadart) package —
general-purpose widgets, extensions, and utilities for building Flutter apps.

## Getting started

```yaml
dependencies:
  zadart_flutter: ^0.1.0
```

```dart
import 'package:zadart_flutter/zadart_flutter.dart';
```

## What's inside

### Widget & `State` extensions

```dart
// Wrap a widget — or a whole list of them — in Expanded.
myWidget.expandWrapped();
[a, b, c].expandWrapped(); // List<Expanded>

// Inside a State:
refreshState();               // setState with no changes, to force a rebuild
setStateMounted(() => ...);   // setState only if the State is still mounted
```

### Snackbars

```dart
showSnackbar(context, 'Saved!'); // hides the current snackbar first by default
```

### Date/time extensions

```dart
final range = DateTimeRange(start: start, end: end);
range.days;              // lazily-iterated days spanned by the range
range.months;            // first-of-month for each month spanned
range.contains(dt);      // inclusive containment

final dt = DateTime.now();
dt.isToday();
dt.clamp(after: earliest, before: latest);
dt.withTime(const TimeOfDay(hour: 9, minute: 0));
```

### flutter_form_builder helpers

```dart
final formKey = GlobalKey<FormBuilderState>();

formKey.isValid;
formKey.saved;                 // the saved values map
formKey.get<String>('email');  // typed field access
formKey.saveAndValidate();
validateFormFields(formKey, ['email', 'name']);
```

`FormBuilderStepperForm` wires up a multi-step form with Back/Next/Submit
buttons and per-step validation:

```dart
FormBuilderStepperForm(
  stepCount: 2,
  stepBuilder: (step, values) => StepData(
    title: 'Step ${step + 1}',
    subtitle: '...',
    fieldNames: const ['email'],
    child: FormBuilderTextField(name: 'email'),
  ),
  onSubmit: (values) => print(values),
);
```

### Number / currency input formatting

`NumberFormatTextInputFormatter` is a `TextInputFormatter` base class that keeps
a text field formatted (via `intl`'s `NumberFormat`) as the user types, while
exposing the parsed `value`. `DecimalNumberFormatTextInputFormatter` is a
ready-to-use implementation backed by `package:decimal` for exact (non-floating
point) amounts:

```dart
TextField(
  inputFormatters: [DecimalNumberFormatTextInputFormatter()],
);
```

Subclass `NumberFormatTextInputFormatter` yourself to support a different
numeric type.

### bloc helpers

```dart
// Build `buildWhen`/`listenWhen`-style change predicates.
selectedStateHasChanged<MyState, int>((s) => s.count);
```

### sfere

`sfere` is a declarative state-propagation system, built on `flutter_bloc`, for
aggregating values contributed from multiple points in the widget tree. It is
included but still lightly documented — see the API docs, with fuller docs and
examples coming in a later release.

## Additional information

Built on top of [`zadart`](https://pub.dev/packages/zadart). Issues and
contributions are welcome at <https://github.com/anqit/zadart_flutter>.
