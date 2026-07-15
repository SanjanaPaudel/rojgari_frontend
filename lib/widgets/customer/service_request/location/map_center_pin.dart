import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class MapCenterPin extends StatelessWidget {
  const MapCenterPin({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: Padding(
      padding: EdgeInsets.only(bottom: 36),
      child: Icon(
        Icons.location_pin,
        color: AppColors.primary,
        size: 48,
        shadows: [Shadow(color: Colors.white, blurRadius: 5)],
      ),
    ),
  );
}
