import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:zadart_flutter/flutter/number_format_text_input_formatter.dart';

/// A concrete [NumberFormatTextInputFormatter] backed by [Decimal] for exact
/// (non-floating-point) numeric input, e.g. currency fields.
class DecimalNumberFormatTextInputFormatter extends NumberFormatTextInputFormatter<Decimal> {
  DecimalNumberFormatTextInputFormatter({
    super.formatter,
    super.enableNegative,
  });

  @override
  Decimal parseNormalized(String normalized) => Decimal.parse(normalized);

  @override
  Decimal scale(Decimal unscaled, int divisor) => (unscaled / Decimal.fromInt(divisor)).toDecimal();

  @override
  dynamic toNumberFormattable(Decimal? value) => DecimalIntl(value ?? Decimal.zero);
}
