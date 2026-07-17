import 'package:flutter/material.dart';

class ServiceCategoryIconResolver {
  ServiceCategoryIconResolver._();

  static IconData resolve({String slug = '', String name = ''}) {
    final category = _normalize('$slug $name');
    if (_containsAny(category, const ['plumbing', 'plumber'])) {
      return Icons.plumbing;
    }
    if (_containsAny(category, const ['electrician', 'electrical'])) {
      return Icons.electrical_services;
    }
    if (category.contains('mechanic')) return Icons.car_repair;
    if (_containsAny(category, const ['gardening', 'gardener'])) {
      return Icons.yard;
    }
    if (_containsAny(category, const ['painting', 'painter'])) {
      return Icons.format_paint;
    }
    if (_containsAny(category, const ['carpenter', 'carpentry'])) {
      return Icons.carpenter;
    }
    if (category.contains('ac repair') ||
        category.contains('air conditioner')) {
      return Icons.ac_unit;
    }
    if (category.contains('appliance repair')) {
      return Icons.home_repair_service;
    }
    if (_containsAny(category, const ['maid', 'cleaning'])) {
      return Icons.cleaning_services;
    }
    if (category.contains('computer repair')) return Icons.computer;
    if (category.contains('television repair') ||
        category.contains('tv repair')) {
      return Icons.tv;
    }
    return Icons.handyman;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);
}
