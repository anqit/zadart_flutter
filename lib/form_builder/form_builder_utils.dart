import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:zadart_flutter/form_builder/form_builder_extensions.dart';

bool validateFormFields(GlobalKey<FormBuilderState> formKey, Iterable<String> fieldNames) =>
    fieldNames.fold(true, (curr, fieldName) =>
        curr && (formKey.fields?[fieldName]?.isValid ?? false));
