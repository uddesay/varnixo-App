import 'package:intl/intl.dart';

/// All prices from the API are BIGINT minor units (paise). This is the
/// single place that converts them to a display string, so a future
/// multi-currency rollout only touches one file.
abstract final class CurrencyFormatter {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats minor units (paise) as a whole-rupee display string, e.g. `₹1,299`.
  static String format(int minorUnits, {String currency = 'INR'}) {
    final double major = minorUnits / 100;
    if (currency == 'INR') return _inr.format(major);
    return NumberFormat.currency(symbol: '$currency ', decimalDigits: 2)
        .format(major);
  }

  static int discountPercent({required int mrpMinor, required int priceMinor}) {
    if (mrpMinor <= 0 || priceMinor >= mrpMinor) return 0;
    return (((mrpMinor - priceMinor) / mrpMinor) * 100).round();
  }
}
