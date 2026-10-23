import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/icon_chip.dart';
import 'package:nest/ui/core/widgets/icon_choice_picker.dart';

/// The single source of truth mapping an expense category name to its icon.
///
/// Keywords are only the fallback: a category may store an explicit [iconKey].
/// Matching is case-insensitive and substring-based, so labels like
/// `Luz e Gás` still resolve. Unknown names fall back to
/// [CategoryIcons.fallback].
abstract final class CategoryIcons {
  /// The key used when nothing matches the category name.
  static const String fallbackKey = 'category';

  /// Shown when no keyword matches and no key is stored.
  static const IconData fallback = Icons.category_outlined;

  /// Every icon the picker offers, in display order.
  static const List<IconOption> options = [
    IconOption('home', 'Casa', Icons.home_outlined),
    IconOption('bolt', 'Eletricidade', Icons.bolt),
    IconOption('water', 'Água', Icons.water_drop_outlined),
    IconOption('fuel', 'Combustível', Icons.local_gas_station_outlined),
    IconOption('fire', 'Gás', Icons.local_fire_department_outlined),
    IconOption('wifi', 'Internet', Icons.wifi),
    IconOption('phone', 'Telemóvel', Icons.smartphone_outlined),
    IconOption('toll', 'Portagens', Icons.toll),
    IconOption('cart', 'Compras', Icons.shopping_cart_outlined),
    IconOption('health', 'Saúde', Icons.medical_services_outlined),
    IconOption('school', 'Educação', Icons.school_outlined),
    IconOption('shield', 'Seguros', Icons.shield_outlined),
    IconOption('bus', 'Transportes', Icons.directions_bus_outlined),
    IconOption('restaurant', 'Restaurantes', Icons.restaurant_outlined),
    IconOption('movie', 'Lazer', Icons.movie_outlined),
    IconOption('subscription', 'Subscrições', Icons.subscriptions_outlined),
    IconOption('music', 'Música', Icons.music_note_outlined),
    IconOption('fitness', 'Ginásio', Icons.fitness_center_outlined),
    IconOption('savings', 'Poupança', Icons.savings_outlined),
    IconOption('pets', 'Animais', Icons.pets_outlined),
    IconOption('clothes', 'Roupa', Icons.checkroom_outlined),
    IconOption('gift', 'Presentes', Icons.card_giftcard_outlined),
    IconOption('category', 'Outra', Icons.category_outlined),
  ];

  /// Keyword sets in priority order; the first keyword contained in the
  /// category name wins, so more specific rules must come first
  /// (e.g. `gasolina` before `gás`).
  static const List<(List<String>, String)> _rules = [
    (['casa', 'renda', 'habitação', 'habitacao'], 'home'),
    (['luz', 'eletricidade', 'electricidade'], 'bolt'),
    (['água', 'agua'], 'water'),
    (['gasolina', 'combustível', 'combustivel', 'diesel'], 'fuel'),
    (['gás', 'gas'], 'fire'),
    (['internet', 'wifi', 'wi-fi'], 'wifi'),
    (['telemóvel', 'telemovel', 'telefone', 'móvel', 'movel'], 'phone'),
    (['via verde', 'portagem', 'portagens'], 'toll'),
    (['supermercado', 'mercado', 'compras', 'compra', 'mercearia'], 'cart'),
    (['saúde', 'saude', 'farmácia', 'farmacia'], 'health'),
    (['educação', 'educacao', 'escola', 'creche'], 'school'),
    (['seguro', 'seguros'], 'shield'),
    (['transporte', 'metro', 'autocarro', 'comboio', 'táxi', 'taxi'], 'bus'),
    (['restaurante', 'café', 'cafe', 'almoço', 'almoco'], 'restaurant'),
    (['lazer', 'diversão', 'diversao', 'cinema'], 'movie'),
    (['subscrição', 'subscricao', 'streaming', 'netflix'], 'subscription'),
    (['música', 'musica', 'spotify'], 'music'),
    (['ginásio', 'ginasio', 'fitness', 'desporto'], 'fitness'),
    (['poupança', 'poupanca', 'objetivo', 'objectivo'], 'savings'),
    (['animal', 'cão', 'cao', 'gato', 'luke'], 'pets'),
    (['roupa', 'vestuário', 'vestuario'], 'clothes'),
    (['presente', 'prenda'], 'gift'),
  ];

  /// Resolves [key] to an icon, falling back to [fallback].
  static IconData forKey(String? key) {
    for (final option in options) {
      if (option.key == key) {
        return option.icon;
      }
    }
    return fallback;
  }

  /// The icon derived from [categoryName] alone, or `null` when none matches.
  static IconData? iconFromName(String categoryName) {
    final name = categoryName.toLowerCase().trim();
    for (final (keywords, key) in _rules) {
      for (final keyword in keywords) {
        if (name.contains(keyword)) {
          return forKey(key);
        }
      }
    }
    return null;
  }

  /// The icon for [categoryName], preferring a stored [iconKey].
  static IconData resolve(String categoryName, String? iconKey) {
    for (final option in options) {
      if (option.key == iconKey) {
        return option.icon;
      }
    }
    return iconFromName(categoryName) ?? fallback;
  }

  /// The key the picker should start on, preferring a stored [iconKey] and
  /// otherwise the heuristic for [categoryName].
  static String initialKey(String categoryName, String? iconKey) {
    for (final option in options) {
      if (option.key == iconKey) {
        return option.key;
      }
    }
    for (final (keywords, key) in _rules) {
      final name = categoryName.toLowerCase().trim();
      for (final keyword in keywords) {
        if (name.contains(keyword)) {
          return key;
        }
      }
    }
    return fallbackKey;
  }
}

/// A circular icon chip standing in for an expense category in a list row.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.iconKey});

  /// The raw category name; used for the colour and the fallback icon.
  final String category;

  /// The stored semantic key, when the category has one.
  final String? iconKey;

  @override
  Widget build(BuildContext context) {
    return IconChip(
      icon: CategoryIcons.resolve(category, iconKey),
      color: context.colors.colorForCategory(category),
    );
  }
}

/// A wrap of tappable category icons; the selected one is highlighted.
class CategoryIconPicker extends StatelessWidget {
  const CategoryIconPicker({
    super.key,
    required this.selectedKey,
    required this.onChanged,
  });

  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconChoicePicker(
      options: CategoryIcons.options,
      selectedKey: selectedKey,
      onChanged: onChanged,
    );
  }
}
