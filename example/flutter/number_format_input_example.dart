import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zadart_flutter/zadart_flutter.dart';

/// A currency field that formats as the user types, backed by [Decimal].
class AmountField extends StatelessWidget {
  final DecimalNumberFormatTextInputFormatter formatter;

  AmountField({super.key})
      : formatter = DecimalNumberFormatTextInputFormatter(
          formatter: NumberFormat.simpleCurrency(decimalDigits: 2),
        );

  @override
  Widget build(BuildContext context) => TextField(
        keyboardType: TextInputType.number,
        inputFormatters: [formatter],
        // `formatter.value` holds the parsed Decimal after each edit.
        onChanged: (_) => debugPrint('amount: ${formatter.value}'),
      );
}

/// Read the parsed value directly off the formatter.
Decimal? currentAmount(DecimalNumberFormatTextInputFormatter formatter) =>
    formatter.value;
