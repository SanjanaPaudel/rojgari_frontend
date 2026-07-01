import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';

enum FieldType {
  phone,
  password,
  email,
  text,
}

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final FieldType fieldType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.fieldType = FieldType.text,
    this.controller,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  final FocusNode _focusNode = FocusNode();

  bool get isPhone => widget.fieldType == FieldType.phone;
  bool get isPassword => widget.fieldType == FieldType.password;
  bool get isEmail => widget.fieldType == FieldType.email;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      setState(() {});
    });
  }

  IconData get fieldIcon {
    if (isPhone) return Icons.phone_outlined;
    if (isPassword) return Icons.lock_outline_rounded;
    if (isEmail) return Icons.email_outlined;
    return Icons.person_outline_rounded;
  }

  TextInputType get keyboardType {
    if (isPhone) return TextInputType.phone;
    if (isEmail) return TextInputType.emailAddress;
    return TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 0),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.lightPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  fieldIcon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Phone Prefix
              if (isPhone) ...[
                const Text(
                  "+977",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(width: 4),

                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.grey,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Container(
                  width: 1,
                  height: 24,
                  color: AppColors.border,
                ),

                const SizedBox(width: 10),
              ],

              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  validator: widget.validator,
                  keyboardType: keyboardType,
                  obscureText: isPassword ? _obscure : false,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintStyle: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              if (isPassword)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                  child: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}