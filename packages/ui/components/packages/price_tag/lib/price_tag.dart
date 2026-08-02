import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:utilities/utilities.dart';

/// Size variants of [PriceTag].
enum PriceTagSize {
  small,
  medium,
  large;

  bool get isSmall => this == PriceTagSize.small;

  bool get isMedium => this == PriceTagSize.medium;

  bool get isLarge => this == PriceTagSize.large;
}

/// Formats and renders a price with the display locale/currency chosen in
/// settings. Every visible price in the app goes through this component.
class PriceTag extends StatelessWidget {
  const PriceTag({
    required this.value,
    required this.locale,
    required this.currencyCode,
    super.key,
    this.size = PriceTagSize.medium,
  });

  final double value;
  final String locale;
  final String currencyCode;
  final PriceTagSize size;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = switch (size) {
      PriceTagSize.small => AppTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
      ),
      PriceTagSize.medium => AppTypography.cardTitle,
      PriceTagSize.large => AppTypography.price,
    };
    return Text(
      Formatters.formatPrice(value, locale: locale, currencyCode: currencyCode),
      style: style.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}
