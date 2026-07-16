import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../models/service_request/selected_service_location.dart';
import '../../../widgets/customer/service_request/location/service_location_section.dart';
import '../../../widgets/customer/service_request/service_request_notification.dart';

class ServiceLocationPickerScreen extends StatefulWidget {
  const ServiceLocationPickerScreen({this.initialLocation, super.key});

  final SelectedServiceLocation? initialLocation;

  @override
  State<ServiceLocationPickerScreen> createState() =>
      _ServiceLocationPickerScreenState();
}

class _ServiceLocationPickerScreenState
    extends State<ServiceLocationPickerScreen> {
  SelectedServiceLocation? _selectedLocation;

  void _confirm() {
    final selected = _selectedLocation;
    if (selected == null || !selected.hasValidCoordinates) {
      ServiceRequestNotifier.show(
        context,
        message: 'Please select a valid service location.',
      );
      return;
    }
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 18, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Service Location',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Move the map to place the pin where service is needed',
                          style: TextStyle(color: AppColors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: ServiceLocationSection(
                  initialLocation: widget.initialLocation,
                  onLocationSelected: (location) {
                    if (!mounted) return;
                    setState(() => _selectedLocation = location);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3EF4), Color(0xFF5124D4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x405B2DE1),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton.icon(
                    onPressed: _selectedLocation == null ? null : _confirm,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      'Confirm Service Location',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
