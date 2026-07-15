import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class ProblemDescriptionField extends StatelessWidget {
  const ProblemDescriptionField({
    required this.controller,
    required this.hint,
    super.key,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFE2DEEB)),
    );
    return TextFormField(
      controller: controller,
      maxLength: 300,
      minLines: 5,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey, height: 1.45),
        contentPadding: const EdgeInsets.all(16),
        filled: true,
        fillColor: Colors.white,
        border: border,
        enabledBorder: border,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.red),
        ),
        counterStyle: const TextStyle(color: AppColors.grey),
        counterText: '${controller.text.length}/300',
      ),
      onChanged: (_) => (context as Element).markNeedsBuild(),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Please describe the problem.'
          : null,
    );
  }
}
