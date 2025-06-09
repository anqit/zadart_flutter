import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

extension FormBuilderExtensions on GlobalKey<FormBuilderState> {
  Map<String, dynamic>? get saved => currentState?.value;

  T? get<T>(String key) => (saved?[key] as T);

  Map<String, dynamic>? get instant => currentState?.instantValue;

  FormBuilderFields? get fields => currentState?.fields;

  void save() => currentState?.save();
  
  bool get isValid => currentState?.isValid ?? false;

  bool? saveAndValidate({ bool focusOnInvalid = false, bool autoScrollWhenFocusOnInvalid = false, }) =>
      currentState?.saveAndValidate(focusOnInvalid: focusOnInvalid, autoScrollWhenFocusOnInvalid: autoScrollWhenFocusOnInvalid);
}
