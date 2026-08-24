import 'package:flutter/widgets.dart';
import 'package:ui_kit/src/theme/ringo_icons.dart';

/// The visual treatments available for a product icon in the Ringo icon font.
enum ProductIconType {
  outline('Outline'),
  bulk('Bulk'),
  solid('Solid'),
  twotone('Two-tone');

  const ProductIconType(this.label);

  final String label;
}

/// A product-relevant icon from the bundled [RingoIcons] set.
class ProductIcon {
  const ProductIcon({
    required this.assetName,
    required this.label,
    required this.outline,
    required this.bulk,
    required this.solid,
    required this.twotone,
  });

  /// Kebab-case source name shared by the bundled SVG treatments.
  final String assetName;
  final String label;
  final IconData outline;
  final IconData bulk;
  final IconData solid;
  final IconData twotone;

  IconData iconFor(ProductIconType type) {
    return switch (type) {
      ProductIconType.outline => outline,
      ProductIconType.bulk => bulk,
      ProductIconType.solid => solid,
      ProductIconType.twotone => twotone,
    };
  }

  /// Returns an SVG only when the treatment contains meaningful opacity.
  /// Outline and solid continue through the smaller icon font.
  String? assetPathFor(ProductIconType type) {
    return switch (type) {
      ProductIconType.bulk => 'assets/product_icons/bulk/$assetName.svg',
      ProductIconType.twotone => 'assets/product_icons/twotone/$assetName.svg',
      ProductIconType.outline || ProductIconType.solid => null,
    };
  }
}

/// Curated Ringo icons that are useful as product visuals.
///
/// Each entry exposes every icon treatment so the selected icon and its type
/// can be stored together.
const kProductIconGallery = <ProductIcon>[
  ProductIcon(
    assetName: 'burger',
    label: 'Burger',
    outline: RingoIcons.burger,
    bulk: RingoIcons.burger_bulk,
    solid: RingoIcons.burger_solid,
    twotone: RingoIcons.burger_twotone,
  ),
  ProductIcon(
    assetName: 'pizza',
    label: 'Pizza',
    outline: RingoIcons.pizza,
    bulk: RingoIcons.pizza_bulk,
    solid: RingoIcons.pizza_solid,
    twotone: RingoIcons.pizza_twotone,
  ),
  ProductIcon(
    assetName: 'chef-hat',
    label: 'Chef hat',
    outline: RingoIcons.chef_hat,
    bulk: RingoIcons.chef_hat_bulk,
    solid: RingoIcons.chef_hat_solid,
    twotone: RingoIcons.chef_hat_twotone,
  ),
  ProductIcon(
    assetName: 'coffee',
    label: 'Coffee',
    outline: RingoIcons.coffee,
    bulk: RingoIcons.coffee_bulk,
    solid: RingoIcons.coffee_solid,
    twotone: RingoIcons.coffee_twotone,
  ),
  ProductIcon(
    assetName: 'cup',
    label: 'Cup',
    outline: RingoIcons.cup,
    bulk: RingoIcons.cup_bulk,
    solid: RingoIcons.cup_solid,
    twotone: RingoIcons.cup_twotone,
  ),
  ProductIcon(
    assetName: 'cupcake',
    label: 'Cupcake',
    outline: RingoIcons.cupcake,
    bulk: RingoIcons.cupcake_bulk,
    solid: RingoIcons.cupcake_solid,
    twotone: RingoIcons.cupcake_twotone,
  ),
  ProductIcon(
    assetName: 'ice-cream',
    label: 'Ice cream',
    outline: RingoIcons.ice_cream,
    bulk: RingoIcons.ice_cream_bulk,
    solid: RingoIcons.ice_cream_solid,
    twotone: RingoIcons.ice_cream_twotone,
  ),
  ProductIcon(
    assetName: 'ramen',
    label: 'Ramen',
    outline: RingoIcons.ramen,
    bulk: RingoIcons.ramen_bulk,
    solid: RingoIcons.ramen_solid,
    twotone: RingoIcons.ramen_twotone,
  ),
  ProductIcon(
    assetName: 'restaurant',
    label: 'Restaurant',
    outline: RingoIcons.restaurant,
    bulk: RingoIcons.restaurant_bulk,
    solid: RingoIcons.restaurant_solid,
    twotone: RingoIcons.restaurant_twotone,
  ),
  ProductIcon(
    assetName: 'bread',
    label: 'Bread',
    outline: RingoIcons.bread,
    bulk: RingoIcons.bread_bulk,
    solid: RingoIcons.bread_solid,
    twotone: RingoIcons.bread_twotone,
  ),
  ProductIcon(
    assetName: 'wine',
    label: 'Wine',
    outline: RingoIcons.wine,
    bulk: RingoIcons.wine_bulk,
    solid: RingoIcons.wine_solid,
    twotone: RingoIcons.wine_twotone,
  ),
  ProductIcon(
    assetName: 'juice',
    label: 'Juice',
    outline: RingoIcons.juice,
    bulk: RingoIcons.juice_bulk,
    solid: RingoIcons.juice_solid,
    twotone: RingoIcons.juice_twotone,
  ),
  ProductIcon(
    assetName: 'donut',
    label: 'Donut',
    outline: RingoIcons.donut,
    bulk: RingoIcons.donut_bulk,
    solid: RingoIcons.donut_solid,
    twotone: RingoIcons.donut_twotone,
  ),
];

/// The prefix used to persist an Ringo icon in `Product.imageUrl`.
const kProductIconPrefix = 'icon:';

/// Persists both an icon's treatment and code point.
///
/// The value is deliberately stored in the existing `imageUrl` column so
/// older databases require no migration. For example:
/// `icon:solid:f2ce`.
String encodeProductIcon(ProductIcon icon, ProductIconType type) {
  final codePoint = icon.iconFor(type).codePoint.toRadixString(16);
  return '$kProductIconPrefix${type.name}:$codePoint';
}

/// Resolves a persisted product icon source, or returns null for another
/// image source (including legacy `stock:` values and device photos).
IconData? resolveProductIcon(String source) {
  if (resolveProductIconType(source) == null) return null;

  final parts = source.substring(kProductIconPrefix.length).split(':');
  final codePoint = int.tryParse(parts.last, radix: 16);
  if (codePoint == null) return null;

  return IconData(codePoint, fontFamily: 'RingoIcons', fontPackage: 'ui_kit');
}

/// Resolves a persisted source back to its curated product icon definition.
///
/// Unknown but otherwise valid Ringo glyphs remain supported by
/// [resolveProductIcon] and simply fall back to font rendering.
ProductIcon? resolveProductIconDefinition(String source) {
  final type = resolveProductIconType(source);
  final resolved = resolveProductIcon(source);
  if (type == null || resolved == null) return null;

  for (final icon in kProductIconGallery) {
    if (icon.iconFor(type).codePoint == resolved.codePoint) return icon;
  }
  return null;
}

/// Reads the persisted visual treatment from an icon source.
ProductIconType? resolveProductIconType(String? source) {
  if (source == null || !source.startsWith(kProductIconPrefix)) return null;

  final parts = source.substring(kProductIconPrefix.length).split(':');
  if (parts.length != 2) return null;

  for (final type in ProductIconType.values) {
    if (type.name == parts.first) return type;
  }
  return null;
}
