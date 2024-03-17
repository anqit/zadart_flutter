import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:zadart/zadart.dart';
import 'package:zadart_flutter/zadart_flutter.dart';

typedef Validator = bool Function(Map<String, dynamic>);

class FormBuilderStepperForm extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;

  final String backText;
  final String nextText;
  final int initialStep;
  final Map<String, dynamic> initialValue;
  final int stepCount;
  final StepData Function(int step, Map<String, dynamic>) stepBuilder;
  final void Function(Map<String, dynamic>)? onSubmit;

  FormBuilderStepperForm({
    super.key,
    required this.stepCount,
    required this.stepBuilder,
    this.initialStep = 0,
    this.initialValue = const {},
    this.onSubmit,
    String? backText,
    String? nextText,
    GlobalKey<FormBuilderState>? formKey,
  }) :
        backText = backText ?? 'Back',
        nextText = nextText ?? 'Next',
        formKey = formKey ?? GlobalKey<FormBuilderState>();

  @override
  State<FormBuilderStepperForm> createState() => _StepperFormState();
}

class _StepperFormState extends State<FormBuilderStepperForm> {
  // late Map<String, dynamic> _values = { ...widget.initialValue };
  late GlobalKey<FormBuilderState> formKey;
  late int _step;
  bool didChangeStep = false;

  Map<String, dynamic> get _values => formKey.instant ?? widget.initialValue;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    formKey = widget.formKey;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.stepBuilder(_step, _values);
    final StepData(:title, :subtitle, :child) = currentStep;
    final valid = isValid(currentStep);

    if (didChangeStep) {
      _setupPostBuildRevalidation(currentStep, valid);
      didChangeStep = false;
    }

    return FormBuilder(
        key: formKey,
        initialValue: widget.initialValue,
        onChanged: refreshState,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Text(title),
            Text(subtitle),
            Expanded(child: child),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(child: _backButton()),
                Container(child: _nextButton(currentStep, valid))
              ],
            )
          ],
        )
    );
  }

  bool get _firstStep => _step == 0;

  bool get _lastStep => _step == widget.stepCount - 1;

  void _stepBack() => setState(() {
    _step--;
    didChangeStep = true;
  });

  void _stepForward(StepData stepData) => setState(() {
    _step++;
    didChangeStep = true;
  });

  Widget? _backButton() =>
      _onBack().map((onBack) => ElevatedButton(onPressed: onBack, child: Text(_backButtonText())));

  Widget? _nextButton(StepData currentStep, bool valid) =>
      _onNext(currentStep).map((onNext) => ElevatedButton(
        onPressed: valid ? onNext : null,
        child: Text(_nextButtonText()),
      ));


  String _backButtonText() => _firstStep ? 'Cancel' : widget.backText;

  String _nextButtonText() => _lastStep ? 'Submit' : widget.nextText;

  void Function()? _onBack() =>
      _firstStep ?
      null : // todo: cancel
      _stepBack;

  void Function()? _onNext(StepData currentStep) =>
      _lastStep ?
          () => widget.onSubmit?.call(_values) // submit if last step
          : () => _stepForward(currentStep);

  bool isValid(StepData currentStep) {
    formKey.saveAndValidate();
    return validateFormFields(formKey, currentStep.fieldNames)
        && (currentStep.validator?.call(_values) ?? true);
  }

  void _setupPostBuildRevalidation(StepData currentStep, bool preRebuildValidity) {
    if (!preRebuildValidity) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (isValid(currentStep)) { // re-check validity after rebuilding
          refreshState();
        }
      });
    } else {
      if (kDebugMode) {
        print('we should never see this');
      } // todo add logging
    }
  }
}

class StepData {
  final String title;
  final String subtitle;
  final Widget child;
  final Validator? validator;
  final List<String> fieldNames;

  const StepData({
    required this.subtitle,
    required this.title,
    required this.child,
    required this.fieldNames,
    this.validator,
  });
}
