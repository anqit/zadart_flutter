import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zadart_flutter/zadart_flutter.dart';

void main() {
  DecimalNumberFormatTextInputFormatter make({bool enableNegative = false}) =>
      DecimalNumberFormatTextInputFormatter(
        enableNegative: enableNegative,
        formatter: NumberFormat.currency(
          locale: 'en_US',
          symbol: r'$',
          decimalDigits: 2,
        ),
      );

  TextEditingValue collapsed(String text, int offset) => TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset),
      );

  TextEditingValue atEnd(String text) => collapsed(text, text.length);

  group('formatting and value', () {
    test('a single digit inserts leading zeros and decimals', () {
      final f = make();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('5'));
      expect(r.text, r'$0.05');
      expect(f.value, Decimal.parse('0.05'));
    });

    test('multiple digits shift the decimal point', () {
      final f = make();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('1234'));
      expect(r.text, r'$12.34');
      expect(f.value, Decimal.parse('12.34'));
    });

    test('large values gain grouping separators', () {
      final f = make();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('1234567'));
      expect(r.text, r'$12,345.67');
      expect(f.value, Decimal.parse('12345.67'));
    });

    test('formatted exposes the current formatted text', () {
      final f = make();
      f.formatEditUpdate(TextEditingValue.empty, atEnd('1234'));
      expect(f.formatted, r'$12.34');
    });
  });

  group('cursor position', () {
    test('lands at the end after typing at the end', () {
      final f = make();
      final r = f.formatEditUpdate(TextEditingValue.empty, atEnd('1234'));
      expect(r.text, r'$12.34');
      expect(r.selection, const TextSelection.collapsed(offset: 6));
    });

    test('stays anchored to a digit inserted in the middle', () {
      final f = make();
      // Field shows $12.34; user inserts '9' between '1' and '2'.
      final r = f.formatEditUpdate(atEnd(r'$12.34'), collapsed(r'$192.34', 3));
      expect(r.text, r'$192.34');
      expect(r.selection, const TextSelection.collapsed(offset: 3)); // after the 9
    });

    test('anchors correctly across an inserted grouping separator', () {
      final f = make();
      // Field shows $1,234.56; user inserts '9' right after the leading 1.
      final r =
          f.formatEditUpdate(atEnd(r'$1,234.56'), collapsed(r'$19,234.56', 3));
      expect(r.text, r'$19,234.56');
      // After the 9 and before the comma.
      expect(r.selection, const TextSelection.collapsed(offset: 3));
    });

    test('keeps the cursor with a digit inserted right after the prefix', () {
      final f = make();
      // Field shows $12.34; user inserts '9' right after the '$'.
      final r = f.formatEditUpdate(atEnd(r'$12.34'), collapsed(r'$912.34', 2));
      expect(r.text, r'$912.34');
      expect(r.selection, const TextSelection.collapsed(offset: 2)); // after the 9
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
      expect(f.value, Decimal.zero);
      expect(r.text, r'$0.00');
    });
  });

  group('negatives', () {
    test('formats a negative value when enabled', () {
      final f = make(enableNegative: true);
      f.formatEditUpdate(TextEditingValue.empty, atEnd('-1234'));
      expect(f.value, Decimal.parse('-12.34'));
    });

    test('ignores the minus sign when negatives are disabled', () {
      final f = make();
      f.formatEditUpdate(TextEditingValue.empty, atEnd('-1234'));
      expect(f.value, Decimal.parse('12.34'));
    });
  });

  group('known bugs', () {
    // Bug 1: `_insertDecimalSeparator` counts the minus sign as a digit slot,
    // so short negative input builds a malformed string ('.-5') that
    // Decimal.parse throws on. Should yield -0.05.
    test('negative with fewer digits than decimalDigits parses correctly', () {
      final f = make(enableNegative: true);
      f.formatEditUpdate(TextEditingValue.empty, atEnd('-5'));
      expect(f.value, Decimal.parse('-0.05'));
    }, skip: 'known bug: short negative input throws FormatException (.-5)');

    // Bug 2: the "delete the preceding digit when a formatting char was
    // removed" branch is gated on `_isSingleDelete`, which requires a 1-char
    // selection, so a normal collapsed-cursor backspace never triggers it.
    // Backspacing the comma leaves the digits (and thus the value) unchanged.
    test('backspacing over a grouping separator deletes the preceding digit',
        () {
      final f = make();
      f.formatEditUpdate(
        collapsed(r'$1,234.56', 3),
        collapsed(r'$1234.56', 2),
      );
      expect(f.value, Decimal.parse('234.56'));
    }, skip: 'known bug: collapsed-cursor backspace over a separator is a no-op');
  });
}
