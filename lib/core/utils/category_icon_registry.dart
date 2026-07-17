import 'package:flutter/material.dart';

/// Resolves the Material icon shown on a customer-home category card.
///
/// `GET /api/services/categories/` returns an `icon` field, but it is not a
/// literal Flutter `Icons.xxx` identifier — the backend sends its own short
/// key (e.g. "plumbing", "ac_repair"). Dart has no reflection, so there is no
/// way to turn an arbitrary string into an `IconData` automatically; every key
/// must be registered once, below.
///
/// Confirmed backend keys (2026-07-17): plumbing, electrical, mechanic,
/// gardening, cleaning, carpentry, painting, ac_repair, computer_repair,
/// tv_repair.
///
/// When the backend adds a brand-new category that reuses one of the keys
/// above, it renders automatically — no frontend change needed. When it
/// introduces a key that isn't listed here yet, add a single entry to
/// [_iconsByKey]; nothing else in the app needs to change. Until that entry is
/// added, [resolve] returns [fallback] so the app never breaks or shows a
/// blank icon.
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

  /// Resolves the icon for a category. Tries the backend-provided [icon] key
  /// first; if that's empty or not yet registered, falls back to matching
  /// [name] against the same known categories (needed because the API
  /// currently sends `icon: ""` for every category); if that also fails,
  /// returns [fallback].
  static IconData resolve({required String icon, required String name}) {
    final byIcon = _iconsByKey[_normalize(icon)];
    if (byIcon != null) return byIcon;
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
