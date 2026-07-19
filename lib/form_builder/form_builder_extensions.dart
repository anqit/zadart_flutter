import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Ergonomic accessors on a `GlobalKey<FormBuilderState>`.
extension FormBuilderExtensions on GlobalKey<FormBuilderState> {
  /// The saved form values, or null if the form has no state yet.
  Map<String, dynamic>? get saved => currentState?.value;

  /// The saved value for [key] cast to [T]. Throws if the value is not a [T]
  /// (including when a non-nullable [T] is requested for an absent key); use
  /// [maybeGet] for a null-returning variant.
  T? get<T>(String key) => (saved?[key] as T);

  /// The saved value for [key] if present and a [T], otherwise null.
  T? maybeGet<T>(String key) => saved?[key] as T?;

  /// The live (unsaved) form values, or null if the form has no state yet.
  Map<String, dynamic>? get instant => currentState?.instantValue;

  /// The form's fields, or null if the form has no state yet.
  FormBuilderFields? get fields => currentState?.fields;

  /// Saves the form.
  void save() => currentState?.save();

  /// Whether the form is currently valid.
  bool get isValid => currentState?.isValid ?? false;

  /// Saves and validates the form, returning its validity (null if no state).
  bool? saveAndValidate({ bool focusOnInvalid = false, bool autoScrollWhenFocusOnInvalid = false, }) =>
      currentState?.saveAndValidate(focusOnInvalid: focusOnInvalid, autoScrollWhenFocusOnInvalid: autoScrollWhenFocusOnInvalid);
}
