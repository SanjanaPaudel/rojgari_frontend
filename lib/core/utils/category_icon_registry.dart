import 'package:flutter/material.dart';

import '../constants/material_icon_codepoints.dart';

/// Resolves the Material icon shown on a customer-home category card.
///
/// The backend stores an icon *name* string in each category's `icon` field
/// (e.g. "cleaning_services", "child_care"), chosen by the admin from the full
/// Material catalog. Dart has no reflection, so [resolve] maps that name in
/// three steps:
///   1. [_iconsByKey] — a small curated map of the app's own semantic keys and
///      preferred glyphs for the common trades (checked first so legacy
///      categories that stored these keys keep their exact look);
///   2. [kMaterialIconCodepoints] — the full Material catalog — rendered
///      dynamically as `IconData(codepoint, fontFamily: 'MaterialIcons')`,
///      which covers ANY icon the admin can pick;
///   3. [_resolveByName] — name-based matching for legacy categories whose
///      `icon` is empty.
/// Anything still unresolved returns [fallback], so a card never shows blank.
///
/// IMPORTANT: step 2 builds [IconData] from a runtime codepoint, so the app
/// MUST be built with `--no-tree-shake-icons` (e.g.
/// `flutter build apk --no-tree-shake-icons`) — otherwise Flutter strips those
/// glyphs and they render as boxes. See material_icon_codepoints.dart.
class CategoryIconRegistry {
  CategoryIconRegistry._();

  static const Map<String, IconData> _iconsByKey = {
    'plumbing': Icons.plumbing,
    'electrical': Icons.electric_bolt,
    'mechanic': Icons.build_outlined,
    'gardening': Icons.local_florist_outlined,
    'cleaning': Icons.cleaning_services_outlined,
    'carpentry': Icons.handyman_outlined,
    'painting': Icons.format_paint_outlined,
    'ac_repair': Icons.ac_unit_outlined,
    'computer_repair': Icons.computer_outlined,
    'tv_repair': Icons.tv_outlined,
  };

  /// Shown when [icon] is empty and [name] doesn't match any known category
  /// either — matches the icon this app has always shown in that case.
  static const IconData fallback = Icons.handyman_outlined;

  static String _normalize(String value) => value
      .toLowerCase()
      .trim()
      .replaceFirst(RegExp(r'^icons\.'), '')
      .replaceAll(RegExp(r'[\s-]+'), '_');

  /// Resolves the icon for a category from its backend [icon] name, with a
  /// [name]-based fallback for legacy categories that have no icon set.
  static IconData resolve({required String icon, required String name}) {
    final key = _normalize(icon);

    final curated = _iconsByKey[key];
    if (curated != null) return curated;

    // Any real Material icon name → render it by codepoint. The non-const
    // IconData is deliberate (dynamic icons); it relies on --no-tree-shake-icons.
    final codepoint = kMaterialIconCodepoints[key];
    if (codepoint != null) {
      // ignore: non_const_argument_for_const_parameter
      return IconData(codepoint, fontFamily: 'MaterialIcons');
    }

    return _resolveByName(_normalize(name));
  }

  static IconData _resolveByName(String normalizedName) {
    if (normalizedName.contains('plumber')) return _iconsByKey['plumbing']!;
    if (normalizedName.contains('electrician')) {
      return _iconsByKey['electrical']!;
    }
    if (normalizedName.contains('mechanic')) return _iconsByKey['mechanic']!;
    if (normalizedName.contains('gardener')) return _iconsByKey['gardening']!;
    if (normalizedName.contains('maid')) return _iconsByKey['cleaning']!;
    if (normalizedName.contains('carpenter')) return _iconsByKey['carpentry']!;
    if (normalizedName.contains('painter')) return _iconsByKey['painting']!;
    if (normalizedName.contains('ac_repair')) return _iconsByKey['ac_repair']!;
    if (normalizedName.contains('computer') ||
        normalizedName.contains('pc_repair')) {
      return _iconsByKey['computer_repair']!;
    }
    if (normalizedName.contains('tv_repair')) return _iconsByKey['tv_repair']!;
    return fallback;
  }
}
