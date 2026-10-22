import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// The single source of truth mapping an expense category name to its icon.
///
/// Matching is case-insensitive and substring-based, so labels like
/// `Luz e Gás` still resolve. Unknown names fall back to
/// [CategoryIcons.fallback].
abstract final class CategoryIcons {
  /// Shown when no keyword matches.
  static const IconData fallback = Icons.category_outlined;

  /// Keyword sets in priority order; the first keyword that is contained in
  /// the category name wins, so more specific rules must come first
  /// (e.g. `gasolina` before `gás`).
  static const List<(List<String>, IconData)> _rules = [
    (['casa', 'renda', 'habitação', 'habitacao'], Icons.home_outlined),
    (['luz', 'eletricidade', 'electricidade'], Icons.bolt),
    (['água', 'agua'], Icons.water_drop_outlined),
    (
      ['gasolina', 'combustível', 'combustivel', 'diesel'],
      Icons.local_gas_station_outlined,
    ),
    (['gás', 'gas'], Icons.local_fire_department_outlined),
    (['internet', 'wifi', 'wi-fi'], Icons.wifi),
    (
      ['telemóvel', 'telemovel', 'telefone', 'móvel', 'movel'],
      Icons.smartphone_outlined,
    ),
    (['via verde', 'portagem', 'portagens'], Icons.toll),
    (
      ['supermercado', 'mercado', 'compras', 'compra', 'mercearia'],
      Icons.shopping_cart_outlined,
    ),
    (
      ['saúde', 'saude', 'farmácia', 'farmacia'],
      Icons.medical_services_outlined,
    ),
    (['educação', 'educacao', 'escola', 'creche'], Icons.school_outlined),
    (['seguro', 'seguros'], Icons.shield_outlined),
    (
      ['transporte', 'metro', 'autocarro', 'comboio', 'táxi', 'taxi'],
      Icons.directions_bus_outlined,
    ),
    (
      ['restaurante', 'café', 'cafe', 'almoço', 'almoco'],
      Icons.restaurant_outlined,
    ),
    (['lazer', 'diversão', 'diversao', 'cinema'], Icons.movie_outlined),
    (
      ['subscrição', 'subscricao', 'streaming', 'netflix'],
      Icons.subscriptions_outlined,
    ),
    (['música', 'musica', 'spotify'], Icons.music_note_outlined),
    (
      ['ginásio', 'ginasio', 'fitness', 'desporto'],
      Icons.fitness_center_outlined,
    ),
    (['poupança', 'poupanca', 'objetivo', 'objectivo'], Icons.savings_outlined),
    (['animal', 'cão', 'cao', 'gato', 'luke'], Icons.pets_outlined),
    (['roupa', 'vestuário', 'vestuario'], Icons.checkroom_outlined),
    (['presente', 'prenda'], Icons.card_giftcard_outlined),
  ];

  /// Resolves the icon for [categoryName].
  static IconData forName(String categoryName) {
    final name = categoryName.toLowerCase().trim();
    for (final (keywords, icon) in _rules) {
      for (final keyword in keywords) {
        if (name.contains(keyword)) {
          return icon;
        }
      }
    }
    return fallback;
  }
}

/// A circular icon chip standing in for an expense category in a list row.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category});

  /// The raw category name; resolved via [CategoryIcons.forName].
  final String category;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.colorForCategory(category);
    return Container(
      width: AppSizes.categoryIcon,
      height: AppSizes.categoryIcon,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.tint),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CategoryIcons.forName(category),
        size: AppSizes.iconLarge,
        color: color,
      ),
    );
  }
}
