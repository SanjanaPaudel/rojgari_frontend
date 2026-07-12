import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

class CustomerAddressSheet extends StatefulWidget {
  const CustomerAddressSheet({super.key, required this.initialAddress});

  final String initialAddress;

  static Future<String?> show(
    BuildContext context, {
    required String initialAddress,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerAddressSheet(initialAddress: initialAddress),
    );
  }

  @override
  State<CustomerAddressSheet> createState() => _CustomerAddressSheetState();
}

class _CustomerAddressSheetState extends State<CustomerAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // BACKEND TODO: Persist this address through PATCH /customer/profile (or a
    // dedicated customer-address endpoint), using the bearer access token.
    // Only update local state after the API confirms the change.
    Navigator.pop(context, _addressController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 12, 22, keyboardInset + 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Manage Address',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Update the address used for your customer profile and service bookings.',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _addressController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    minLines: 2,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter your current address',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 42),
                        child: Icon(Icons.location_on_outlined),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAF9FD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Address'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
