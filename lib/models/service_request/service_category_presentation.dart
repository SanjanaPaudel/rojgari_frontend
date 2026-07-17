import 'package:flutter/material.dart';

import 'service_category.dart';

class ServiceCategoryPresentation {
  const ServiceCategoryPresentation._();

  static String _normalized(String slug) =>
      slug.trim().toLowerCase().replaceAll('_', '-');

  static IconData iconFor(String slug) {
    switch (_normalized(slug)) {
      case 'plumber':
      case 'plumbing':
        return Icons.plumbing;
      case 'electrician':
      case 'electrical':
        return Icons.electrical_services;
      case 'mechanic':
      case 'vehicle-repair':
        return Icons.car_repair;
      case 'gardener':
      case 'gardening':
        return Icons.yard;
      case 'painter':
      case 'painting':
        return Icons.format_paint;
      case 'carpenter':
      case 'carpentry':
        return Icons.handyman;
      case 'ac-repair':
      case 'air-conditioner':
        return Icons.ac_unit;
      case 'appliance-repair':
        return Icons.kitchen;
      case 'maid':
      case 'cleaning':
      case 'maid-cleaning':
        return Icons.cleaning_services;
      case 'computer-repair':
      case 'pc-repair':
        return Icons.computer;
      default:
        return Icons.home_repair_service_outlined;
    }
  }

  static String serviceTitleFor(ServiceCategory category) {
    final name = category.name.trim();
    if (name.isEmpty) return 'Service';
    return name.toLowerCase().endsWith('service') ? name : '$name Service';
  }

  static String issueLabelFor(ServiceCategory category) {
    switch (_normalized(category.slug)) {
      case 'plumber':
      case 'plumbing':
        return 'Plumbing Issue';
      case 'electrician':
      case 'electrical':
        return 'Electrical Issue';
      case 'maid':
      case 'cleaning':
      case 'maid-cleaning':
        return 'Cleaning Issue';
      default:
        final name = category.name.trim();
        return '${name.isEmpty ? 'Service' : name} Issue';
    }
  }

  static String problemHintFor(String slug) {
    switch (_normalized(slug)) {
      case 'plumber':
      case 'plumbing':
        return 'e.g. Kitchen pipe is leaking under the sink and water is dripping onto the floor...';
      case 'electrician':
      case 'electrical':
        return 'e.g. The bedroom socket is sparking and some lights are not working...';
      case 'mechanic':
      case 'vehicle-repair':
        return 'e.g. My vehicle is making an unusual noise and is difficult to start...';
      case 'gardener':
      case 'gardening':
        return 'e.g. The garden needs trimming and the plants require maintenance...';
      default:
        return 'e.g. Describe the problem, when it started and what help you need...';
    }
  }
}
