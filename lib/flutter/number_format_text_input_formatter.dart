import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zadart/zadart.dart';

abstract class NumberFormatTextInputFormatter<T> extends TextInputFormatter {
  static final _defaultFormatter = NumberFormat.simpleCurrency(decimalDigits: 2);
  final NumberFormat formatter;

  /// Whether to allow negative numbers, default is false
  final bool enableNegative;

  String? _formatted;

  T? _lastValue;

  T? get value => _lastValue;

  String? get formatted => _formatted;

  NumberFormatTextInputFormatter({
    NumberFormat? formatter,
    this.enableNegative = false,
  }) : formatter = formatter ?? _defaultFormatter;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue,) {
    final (oldNormalizedText, _, _) = _normalizeTextEditingValue(oldValue);
    var (newNormalizedText, newCharsAfterStart, newCharsAfterEnd) = _normalizeTextEditingValue(newValue);

    if (_isSingleDelete(oldValue, newValue)) {
      if (oldNormalizedText == newNormalizedText && newCharsAfterStart != newNormalizedText.length) {
        // cursor was after a non-delete-able (formatting) character, remove the preceding delete-able character instead
        // character instead, if there is one
        newNormalizedText = newNormalizedText.substring(0, newNormalizedText.length - newCharsAfterStart - 1)
            + newNormalizedText.substring(newNormalizedText.length - newCharsAfterEnd);
      }
    }

    String updatedText = _insertDecimalSeparator(newNormalizedText);
    _lastValue = scale(parseNormalized(updatedText), formatter.multiplier);
    _formatted = formatter.format(toNumberFormattable(_lastValue));

    final (newDenormalizedStart, newDenormalizedEnd) =
        _adjustSelectionBoundaries(_formatted!, newCharsAfterStart, newCharsAfterEnd);

    return TextEditingValue(
      text: _formatted!,
      selection: TextSelection(baseOffset: newDenormalizedStart, extentOffset: newDenormalizedEnd),
    );
  }

  T parseNormalized(String normalized);

  T scale(T unscaled, int divisor);

  dynamic toNumberFormattable(T? value);

  /// returns just the editable characters of the value, i.e. the digits and characters NOT added by formatting
  /// (such as the decimal point, grouping separators, any currency symbols, etc), as well as the number of those
  /// characters that appear after the limits of the selection, adjusting the selection as needed to account for
  /// the removal of the formatting characters
  (String normalizedText, int charsAfterStart, int charsAfterEnd) _normalizeTextEditingValue(TextEditingValue val) {
    var text = val.text;

    // TODO the minus sign proceeds, rather than precedes, the digits in some locales
    String normalizedText =
      text.startsWith(formatter.symbols.MINUS_SIGN) && enableNegative ? formatter.symbols.MINUS_SIGN : '';
    var charsAfterStart = 0, charsAfterEnd = 0;

    for (int i = 0; i < text.length; i++) {
      // TODO: does minus sign at i = 0 need to increment charsAfter[Start/End] ?
      if (text[i].isDigit) {
        normalizedText += text[i];
        if (i >= val.selection.start) charsAfterStart++;
        if (i >= val.selection.end) charsAfterEnd++;
      }
    }

    return (normalizedText, charsAfterStart, charsAfterEnd);
  }

  (int denormalizedStart, int denormalizedEnd) _adjustSelectionBoundaries(String formattedText, int charsAfterStart, int charsAfterEnd) {
    var editableCharsCount = 0;
    var denormalizedStart = formattedText.length, denormalizedEnd = formattedText.length;

    for (int i = formattedText.length - 1; i >= 0; i--) {
      if (formattedText[i].isDigit) {
        editableCharsCount++;
      }
      if (editableCharsCount <= charsAfterStart) {
        denormalizedStart--;
      }
      if (editableCharsCount <= charsAfterEnd) {
        denormalizedEnd--;
      }
    }

    final lowerLimit = _isNeg(formattedText) ? formatter.negativePrefix.length : formatter.positivePrefix.length;
    final upperLimit = formattedText.length - (_isNeg(formattedText) ? formatter.negativeSuffix.length : formatter.positiveSuffix.length);

    return (denormalizedStart.clamp(lowerLimit, upperLimit), denormalizedEnd.clamp(lowerLimit, upperLimit));
  }

  bool _isNeg(String formattedText) =>
      formattedText.startsWith(formatter.negativePrefix) || formattedText.endsWith(formatter.negativeSuffix);

  bool _isSingleDelete(TextEditingValue oldValue, TextEditingValue newValue) {
    final TextEditingValue(text: oldText, selection: oldSelection) = oldValue;
    final TextEditingValue(text: newText) = newValue;
    int selectionSize = oldSelection.isValid ? oldSelection.end - oldSelection.start : 0;
    int lengthDelta = newText.length - oldText.length;

    return lengthDelta == -1 && selectionSize == 1;
  }

  String _insertDecimalSeparator(String text) {
    if(!text.contains(formatter.symbols.DECIMAL_SEP)) {
      // TODO get default decimal digits more robustly according to the formatter
      final decimalDigits = formatter.decimalDigits ?? 2;
      if (text.length >= decimalDigits) {
        return text.substring(0, text.length - decimalDigits) +
            formatter.symbols.DECIMAL_SEP +
            text.substring(text.length - decimalDigits);
      } else {
        final delta = decimalDigits - text.length;
        final zero = formatter.symbols.ZERO_DIGIT;
        final point = formatter.symbols.DECIMAL_SEP;
        return '$zero$point${zero * delta}$text';
      }
    }
    return text;
  }

  // ignore: unused_element
  bool _isValidNonDigitChar(String char) =>
      {
        formatter.currencySymbol,
        formatter.positivePrefix,
        if (enableNegative) formatter.negativePrefix,
        formatter.positiveSuffix,
        if (enableNegative) formatter.negativeSuffix,
        formatter.symbols.DECIMAL_SEP,
        formatter.symbols.GROUP_SEP,
        formatter.symbols.PERCENT,
        if (enableNegative) formatter.symbols.MINUS_SIGN,
      }.expand((e) => e.split('').toSet()).contains(char);
}
