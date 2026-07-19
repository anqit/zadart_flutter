import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Which end of the number the field fills toward: the right for left-to-right
/// scripts, the left for right-to-left scripts.
enum NumberFieldDirection { ltr, rtl }

/// A general, model-based successor to `NumberFormatTextInputFormatter`.
///
/// Instead of re-scanning the new text for ASCII digits, it treats the entered
/// digits (plus a sign) as the canonical value, diffs each edit against the
/// previous text so edits over formatting characters are unambiguous, and
/// re-renders through the [NumberFormat]. Digit detection is driven by the
/// format's `ZERO_DIGIT`, so non-Latin digits and either text [direction] work.
///
/// Experimental: not yet exported from the package barrel.
abstract class NumberFieldFormatter<T> extends TextInputFormatter {
  static final _defaultFormatter = NumberFormat.simpleCurrency(decimalDigits: 2);

  final NumberFormat formatter;
  final bool enableNegative;

  /// The end the field fills toward. Defaults to the [formatter]'s locale
  /// directionality (via `Bidi.isRtlLanguage`); pass a value to override.
  final NumberFieldDirection direction;

  T? _value;
  String? _formatted;

  /// The most recently parsed value.
  T? get value => _value;

  /// The most recently formatted text.
  String? get formatted => _formatted;

  NumberFieldFormatter({
    NumberFieldDirection? direction,
    this.enableNegative = false,
    NumberFormat? formatter,
  })  : formatter = formatter ?? _defaultFormatter,
        direction = direction ??
            (Bidi.isRtlLanguage((formatter ?? _defaultFormatter).locale)
                ? NumberFieldDirection.rtl
                : NumberFieldDirection.ltr);

  /// Parses an ASCII value string like `-12.34` (or `123` for integer formats)
  /// into a [T].
  T parseSigned(String asciiSigned);

  /// Scales [unscaled] by the format's [multiplier] (e.g. 100 for percent).
  T scale(T unscaled, int multiplier);

  /// Converts [value] into a value the [NumberFormat] can format.
  dynamic toNumberFormattable(T? value);

  int get _zero => formatter.symbols.ZERO_DIGIT.codeUnitAt(0);

  bool _isDigit(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 0x30 && c <= 0x39) || (c >= _zero && c < _zero + 10);
  }

  String _toAscii(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 0x30 && c <= 0x39) ? ch : String.fromCharCode(0x30 + c - _zero);
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue neu) {
    final before = _parse(old);
    var after = _parse(neu);

    // The only ambiguous edit is a pure deletion (nothing inserted) that removed
    // no value digit — the user deleted a formatting character. Resolve it with
    // the caret: drop the value digit on the side the caret moved from.
    final (:inserted, :removed) = _diff(old.text, neu.text);
    if (inserted.isEmpty && removed.isNotEmpty && after.digits == before.digits) {
      after = _deleteAdjacentDigit(
        before,
        backspace: neu.selection.start < old.selection.start,
      );
    }

    final value = _digitsToValue(after.digits, after.negative);
    final formatted = formatter.format(toNumberFormattable(value));
    _value = value;
    _formatted = formatted;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: _caretOffset(formatted, after)),
    );
  }

  /// The removed/inserted regions between [a] and [b], via their longest common
  /// prefix and suffix. Only `inserted.isEmpty` is consumed, which is invariant
  /// to prefix-vs-suffix bias, so this stays direction-independent.
  ({String removed, String inserted}) _diff(String a, String b) {
    final maxPrefix = a.length < b.length ? a.length : b.length;
    var p = 0;
    while (p < maxPrefix && a[p] == b[p]) {
      p++;
    }
    var s = 0;
    while (s < maxPrefix - p && a[a.length - 1 - s] == b[b.length - 1 - s]) {
      s++;
    }
    return (
      removed: a.substring(p, a.length - s),
      inserted: b.substring(p, b.length - s),
    );
  }

  /// Extracts the canonical value from a raw `(text, selection)`.
  _Entry _parse(TextEditingValue v) {
    final text = v.text;
    final caret = v.selection.isValid ? v.selection.start : text.length;

    final digits = StringBuffer();
    final digitIndices = <int>[];
    for (var i = 0; i < text.length; i++) {
      if (_isDigit(text[i])) {
        digits.write(_toAscii(text[i]));
        digitIndices.add(i);
      }
    }

    final negative = enableNegative && text.contains(formatter.symbols.MINUS_SIGN);

    // `anchor` is the number of value-digits between the caret and the fill end.
    final anchor = direction == NumberFieldDirection.ltr
        ? digitIndices.where((i) => i >= caret).length // digits to the right
        : digitIndices.where((i) => i < caret).length; // digits to the left

    return _Entry(negative, digits.toString(), anchor);
  }

  /// Removes the value digit adjacent to the caret after a formatting-only
  /// deletion (fixes the "backspace over a separator does nothing" case).
  _Entry _deleteAdjacentDigit(_Entry before, {required bool backspace}) {
    final total = before.digits.length;
    if (total == 0) return before;

    final int removeIndex; // index into the MSB-first digit string
    final int newAnchor;
    if (direction == NumberFieldDirection.ltr) {
      final toLeft = total - before.anchor;
      removeIndex = backspace ? toLeft - 1 : toLeft;
      newAnchor = backspace ? before.anchor : before.anchor - 1;
    } else {
      removeIndex = backspace ? before.anchor - 1 : before.anchor;
      newAnchor = backspace ? before.anchor - 1 : before.anchor;
    }

    if (removeIndex < 0 || removeIndex >= total) return before;
    final digits =
        before.digits.substring(0, removeIndex) + before.digits.substring(removeIndex + 1);
    return _Entry(before.negative, digits, newAnchor);
  }

  /// Builds the value by placing the decimal a fixed number of digits from the
  /// end, keeping the sign separate.
  T _digitsToValue(String digits, bool negative) {
    final decimals = formatter.decimalDigits ?? 2;
    final String body;
    if (decimals == 0) {
      body = digits.isEmpty ? '0' : digits;
    } else {
      final padded = digits.padLeft(decimals + 1, '0');
      final cut = padded.length - decimals;
      body = '${padded.substring(0, cut)}.${padded.substring(cut)}';
    }
    return scale(parseSigned(negative ? '-$body' : body), formatter.multiplier);
  }

  /// Places the caret so that [_Entry.anchor] value-digits sit between it and
  /// the fill end of the rendered text.
  int _caretOffset(String formatted, _Entry e) {
    final positions = <int>[
      for (var i = 0; i < formatted.length; i++)
        if (_isDigit(formatted[i])) i,
    ];
    final total = positions.length;
    final digitsToLeft =
        direction == NumberFieldDirection.ltr ? total - e.anchor : e.anchor;

    final int offset;
    if (total == 0) {
      offset = formatted.length;
    } else if (digitsToLeft <= 0) {
      offset = positions.first; // before the first digit
    } else if (digitsToLeft >= total) {
      offset = positions.last + 1; // after the last digit
    } else {
      offset = positions[digitsToLeft - 1] + 1; // after the digitsToLeft-th digit
    }

    final neg = _isNegativeFormat(formatted);
    final lo = (neg ? formatter.negativePrefix : formatter.positivePrefix).length;
    final hi = formatted.length -
        (neg ? formatter.negativeSuffix : formatter.positiveSuffix).length;
    return offset.clamp(lo, hi);
  }

  bool _isNegativeFormat(String formatted) =>
      (formatter.negativePrefix.isNotEmpty &&
          formatted.startsWith(formatter.negativePrefix)) ||
      (formatter.negativeSuffix.isNotEmpty &&
          formatted.endsWith(formatter.negativeSuffix));
}

class _Entry {
  final bool negative;
  final String digits; // ASCII, most-significant first
  final int anchor; // digits between the caret and the fill end

  const _Entry(this.negative, this.digits, this.anchor);
}

/// A [NumberFieldFormatter] backed by [Decimal] for exact amounts.
class DecimalNumberFieldFormatter extends NumberFieldFormatter<Decimal> {
  DecimalNumberFieldFormatter({
    super.formatter,
    super.enableNegative,
    super.direction,
  });

  @override
  Decimal parseSigned(String asciiSigned) => Decimal.parse(asciiSigned);

  @override
  Decimal scale(Decimal unscaled, int multiplier) =>
      (unscaled / Decimal.fromInt(multiplier)).toDecimal();

  @override
  dynamic toNumberFormattable(Decimal? value) => DecimalIntl(value ?? Decimal.zero);
}
