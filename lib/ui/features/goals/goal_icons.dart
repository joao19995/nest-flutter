import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/icon_chip.dart';
import 'package:nest/ui/core/widgets/icon_choice_picker.dart';

/// The goal icon set and the key-to-icon mapping.
///
/// Keys are stored by the API, so they must stay stable. Unknown or missing
/// keys fall back to [fallback].
abstract final class GoalIcons {
  /// The key used when the user has not picked an icon.
  static const String defaultKey = 'flag';

  /// Shown when the stored key is unknown or absent.
  static const IconData fallback = Icons.flag_outlined;

  /// Every icon the picker offers, in display order.
  static const List<IconOption> options = [
    IconOption('flag', 'Bandeira', Icons.flag_outlined),
    IconOption('plane', 'Viagem', Icons.flight_outlined),
    IconOption('palm', 'Praia', Icons.beach_access_outlined),
    IconOption('compass', 'Explorar', Icons.explore_outlined),
    IconOption('car', 'Carro', Icons.directions_car_outlined),
    IconOption('bike', 'Bicicleta', Icons.pedal_bike_outlined),
    IconOption('home', 'Casa', Icons.home_outlined),
    IconOption('shield', 'Proteção', Icons.shield_outlined),
    IconOption('piggy-bank', 'Poupança', Icons.savings_outlined),
    IconOption('wallet', 'Carteira', Icons.account_balance_wallet_outlined),
    IconOption('graduation-cap', 'Educação', Icons.school_outlined),
    IconOption('heart', 'Saúde', Icons.favorite_outline),
    IconOption('laptop', 'Tecnologia', Icons.laptop_mac_outlined),
    IconOption('camera', 'Fotografia', Icons.photo_camera_outlined),
    IconOption('music', 'Música', Icons.music_note_outlined),
    IconOption('dumbbell', 'Desporto', Icons.fitness_center_outlined),
    IconOption('baby', 'Bebé', Icons.child_care_outlined),
    IconOption('paw', 'Animal', Icons.pets_outlined),
    IconOption('ring', 'Anel', Icons.diamond_outlined),
    IconOption('gift', 'Presente', Icons.card_giftcard_outlined),
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

  /// Resolves [key] to a known key, falling back to [defaultKey].
  static String resolveKey(String? key) {
    for (final option in options) {
      if (option.key == key) {
        return option.key;
      }
    }
    return defaultKey;
  }
}

/// A circular chip holding a goal's icon.
///
/// The tinted background uses the same name-derived palette as expense
/// categories, so both catalogues read the same way.
class GoalIcon extends StatelessWidget {
  const GoalIcon({
    super.key,
    required this.name,
    required this.iconKey,
    this.size = AppSizes.goalIcon,
    this.iconSize = AppSizes.iconLarge,
  });

  /// The goal name; drives the chip colour.
  final String name;

  /// The stored semantic key; resolved via [GoalIcons.forKey].
  final String? iconKey;

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconChip(
      icon: GoalIcons.forKey(iconKey),
      color: context.colors.colorForCategory(name),
      size: size,
      iconSize: iconSize,
    );
  }
}

/// A wrap of tappable goal icons; the selected one is highlighted.
class GoalIconPicker extends StatelessWidget {
  const GoalIconPicker({
    super.key,
    required this.selectedKey,
    required this.onChanged,
  });

  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconChoicePicker(
      options: GoalIcons.options,
      selectedKey: selectedKey,
      onChanged: onChanged,
    );
  }
}
