import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:zadart_flutter/zadart_flutter.dart';

/// Ergonomic helpers on a `GlobalKey<FormBuilderState>`.
void formKeyHelpers(GlobalKey<FormBuilderState> formKey) {
  formKey.isValid; // currentState?.isValid ?? false
  formKey.saved; // the saved values map, or null
  formKey.get<String>('email'); // typed access to a saved field
  formKey.saveAndValidate();

  // Validate just a subset of fields (e.g. the current wizard step).
  validateFormFields(formKey, const ['email', 'name']);
}

/// `FormBuilderStepperForm` wires up a multi-step form with Back/Next/Submit
/// buttons and per-step validation.
Widget wizard() => FormBuilderStepperForm(
      stepCount: 2,
      stepBuilder: (step, values) => switch (step) {
        0 => StepData(
            title: 'Your email',
            subtitle: 'Step 1 of 2',
            fieldNames: const ['email'],
            child: FormBuilderTextField(name: 'email'),
          ),
        _ => StepData(
            title: 'Your name',
            subtitle: 'Step 2 of 2',
            fieldNames: const ['name'],
            child: FormBuilderTextField(name: 'name'),
          ),
      },
      onSubmit: (values) => debugPrint('submitted: $values'),
    );
