import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/nest_colors.dart';

/// Maps a category name to a stable accent colour from the active palette.
extension CategoryColorsX on NestColors {
  /// The palette colour for [name].
  ///
  /// The same name always resolves to the same colour, independent of the
  /// brightness; matching is trimmed and case-insensitive. Light and dark
  /// palettes have the same length, so a category keeps its slot in both.
  Color colorForCategory(String name) {
    return categoryPalette[_stableHash(name) % categoryPalette.length];
  }
}

/// A small deterministic string hash (djb2-style).
///
/// `String.hashCode` is not guaranteed to be stable across runs or platforms,
/// so the mapping uses its own hash. The mask keeps the value within 32 bits
/// and safe for the web runtime's 53-bit integers.
int _stableHash(String value) {
  var hash = 5381;
  for (final unit in value.trim().toLowerCase().codeUnits) {
    hash = (hash * 33 + unit) & 0x7FFFFFFF;
  }
  return hash;
}
