import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zadart_flutter/flutter/number_field_formatter.dart';

void main() {
  DecimalNumberFieldFormatter make({
    bool enableNegative = false,
    int decimalDigits = 2,
  }) =>
      DecimalNumberFieldFormatter(
        enableNegative: enableNegative,
        formatter: NumberFormat.currency(
          locale: 'en_US',
          symbol: r'$',
          decimalDigits: decimalDigits,
        ),
      );

  TextEditingValue collapsed(String text, int offset) => TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset),
      );

  TextEditingValue atEnd(String text) => collapsed(text, text.length);

  TextEditingValue ranged(String text, int base, int extent) => TextEditingValue(
        text: text,
        selection: TextSelection(baseOffset: base, extentOffset: extent),
      );

  group('formatting and value', () {
    test('single digit', () {
      final f = make();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('5'));
      expect(r.text, r'$0.05');
      expect(f.value, Decimal.parse('0.05'));
    });

    test('multiple digits', () {
      final f = make();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('1234'));
      expect(r.text, r'$12.34');
      expect(f.value, Decimal.parse('12.34'));
    });

    test('grouping separators', () {
      final f = make();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('1234567'));
      expect(r.text, r'$12,345.67');
      expect(f.value, Decimal.parse('12345.67'));
    });
  });

  group('cursor position', () {
    test('at the end after typing at the end', () {
      final f = make();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('1234'));
      expect(r.selection, const TextSelection.collapsed(offset: 6));
    });

    test('anchored to a digit inserted in the middle', () {
      final f = make();
      final r = f.formatEditUpdate(atEnd(r'$12.34'), collapsed(r'$192.34', 3));
      expect(r.text, r'$192.34');
      expect(r.selection, const TextSelection.collapsed(offset: 3));
    });

    test('anchored across an inserted grouping separator', () {
      final f = make();
      final r =
          f.formatEditUpdate(atEnd(r'$1,234.56'), collapsed(r'$19,234.56', 3));
      expect(r.text, r'$19,234.56');
      expect(r.selection, const TextSelection.collapsed(offset: 3));
    });

    test('digit inserted right after the prefix', () {
      final f = make();
      final r = f.formatEditUpdate(atEnd(r'$12.34'), collapsed(r'$912.34', 2));
      expect(r.text, r'$912.34');
      expect(r.selection, const TextSelection.collapsed(offset: 2));
    });
  });

  group('deletion', () {
    test('backspacing a trailing digit shifts the decimal back', () {
      final f = make();
      final r = f.formatEditUpdate(atEnd(r'$12.34'), atEnd(r'$12.3'));
      expect(r.text, r'$1.23');
      expect(f.value, Decimal.parse('1.23'));
    });

    test('clearing all input yields zero', () {
      final f = make();
      final r = f.formatEditUpdate(atEnd(r'$0.05'), atEnd(''));
      expect(r.text, r'$0.00');
      expect(f.value, Decimal.zero);
    });

    test('backspacing over a grouping separator deletes the preceding digit',
        () {
      final f = make();
      f.formatEditUpdate(collapsed(r'$1,234.56', 3), collapsed(r'$1234.56', 2));
      expect(f.value, Decimal.parse('234.56'));
    });
  });

  group('selection replacement', () {
    test('replacing a range (spanning a separator) with a digit', () {
      final f = make();
      // Select ",234" in $1,234.56 and type '9'.
      final r = f.formatEditUpdate(ranged(r'$1,234.56', 2, 6), collapsed(r'$19.56', 3));
      expect(r.text, r'$19.56');
      expect(f.value, Decimal.parse('19.56'));
      expect(r.selection, const TextSelection.collapsed(offset: 3));
    });

    test('replacing a range with an invalid character drops it', () {
      final f = make();
      // Select ",234" and type a letter — the letter is ignored.
      f.formatEditUpdate(ranged(r'$1,234.56', 2, 6), collapsed(r'$1a.56', 3));
      expect(f.value, Decimal.parse('1.56'));
    });
  });

  group('negatives', () {
    test('formats a negative value when enabled', () {
      final f = make(enableNegative: true);
      f.formatEditUpdate(TextEditingValue.empty, atEnd('-1234'));
      expect(f.value, Decimal.parse('-12.34'));
    });

    test('short negative input parses (no FormatException)', () {
      final f = make(enableNegative: true);
      f.formatEditUpdate(TextEditingValue.empty, atEnd('-5'));
      expect(f.value, Decimal.parse('-0.05'));
    });

    test('ignores the minus sign when negatives are disabled', () {
      final f = make();
      f.formatEditUpdate(TextEditingValue.empty, atEnd('-1234'));
      expect(f.value, Decimal.parse('12.34'));
    });
  });

  group('other formats', () {
    test('integer format (no decimal digits)', () {
      final f = make(decimalDigits: 0);
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('5'));
      expect(r.text, r'$5');
      expect(f.value, Decimal.fromInt(5));
    });

    test('accepts ASCII input under a non-Latin-digit locale', () {
      final f = DecimalNumberFieldFormatter(
        formatter: NumberFormat.currency(locale: 'ar', decimalDigits: 2),
      );
      f.formatEditUpdate(TextEditingValue.empty, atEnd('1234'));
      expect(f.value, Decimal.parse('12.34'));
    });
  });

  group('direction default', () {
    test('defaults to ltr for a Latin locale', () {
      final f = DecimalNumberFieldFormatter(
        formatter: NumberFormat.currency(locale: 'en_US'),
      );
      expect(f.direction, NumberFieldDirection.ltr);
    });

    test('defaults to rtl for an RTL locale', () {
      final f = DecimalNumberFieldFormatter(
        formatter: NumberFormat.currency(locale: 'ar'),
      );
      expect(f.direction, NumberFieldDirection.rtl);
    });

    test('explicit direction overrides the locale default', () {
      final f = DecimalNumberFieldFormatter(
        direction: NumberFieldDirection.ltr,
        formatter: NumberFormat.currency(locale: 'ar'),
      );
      expect(f.direction, NumberFieldDirection.ltr);
    });
  });

  group('rtl locale formatting', () {
    DecimalNumberFieldFormatter ar({NumberFieldDirection? direction}) =>
        DecimalNumberFieldFormatter(
          direction: direction,
          formatter: NumberFormat.currency(locale: 'ar', decimalDigits: 2),
        );

    test('formats value and caret for an Arabic (RTL) locale', () {
      final f = ar();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('1234'));
      expect(f.value, Decimal.parse('12.34'));
      expect(r.text, '‏12.34 EGP'); // RLM + "12.34" + nbsp + "EGP"
      expect(r.selection, const TextSelection.collapsed(offset: 6));
    });

    test('anchors caret to a digit inserted mid-number (RTL locale)', () {
      final f = ar();
      // "‏12.34 EGP" -> insert '9' after the leading '1'.
      final r = f.formatEditUpdate(
        atEnd('‏12.34 EGP'),
        collapsed('‏192.34 EGP', 3),
      );
      expect(f.value, Decimal.parse('192.34'));
      expect(r.text, '‏192.34 EGP');
      expect(r.selection, const TextSelection.collapsed(offset: 3));
    });

    test('parses non-Latin (Persian) digits and renders them', () {
      final f = DecimalNumberFieldFormatter(
        formatter: NumberFormat.currency(locale: 'fa', decimalDigits: 2),
      );
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('1234'));
      expect(f.value, Decimal.parse('12.34'));
      expect(r.text.runes.any((c) => c >= 0x6f0 && c <= 0x6f9), isTrue);
    });

    test('direction ltr and rtl produce identical output (parameter is inert)',
        () {
      final old = atEnd('‏12.34 EGP');
      final input = collapsed('‏192.34 EGP', 3);
      final withLtr = ar(direction: NumberFieldDirection.ltr)
          .formatEditUpdate(old, input);
      final withRtl = ar(direction: NumberFieldDirection.rtl)
          .formatEditUpdate(old, input);
      expect(withLtr.text, withRtl.text);
      expect(withLtr.selection, withRtl.selection);
    });
  });
}
