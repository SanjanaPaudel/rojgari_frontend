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

  //Variable in CustomTextField
  final String label;
  final String hintText;
  final FieldType fieldType;  // What kind of field -> phone, password, email or text
  final TextEditingController? controller;  //TextEditingController job is to know what the user typed . Now ? means control variable stores the TextEditingContoller object or null
  final String? errorMsg; // Stores the error msg to display under the textfield
  final FocusNode? focusNode;
  final bool enabled;
  final bool showLabel;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.fieldType = FieldType.text,
    this.controller,
    this.errorMsg,
    this.focusNode,
    this.enabled = true,
    this.showLabel = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // _ indicate private variable
  bool _obscure = true;  //controls password visibility ( tapping on eye ) ture -> password hidden , false -> password visible
  String? _errorText; // error shown below the field
  bool _hasError = false; //false mean valid

  late FocusNode _focusNode;

  bool get isPhone => widget.fieldType == FieldType.phone;
  bool get isPassword => widget.fieldType == FieldType.password;
  bool get isEmail => widget.fieldType == FieldType.email;

  @override
  void initState() {
    super.initState();

    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(() {
      setState(() {});
    });

    _errorText = widget.errorMsg;
    _hasError = widget.errorMsg != null;
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.errorMsg != widget.errorMsg) {
      setState(() {
        _errorText = widget.errorMsg;
        _hasError = widget.errorMsg != null;
      });
    }
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
        if (widget.showLabel)
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),

        const SizedBox(height: 5),

        Container(
          constraints: const BoxConstraints(
            minHeight: 50,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hasError
                  ? Colors.red
                  : _focusNode.hasFocus
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

              if (isPhone) ...[
                const Text(
                  "+977",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 2,
                  height: 24,
                  color: AppColors.border,
                ),
                const SizedBox(width: 10),
              ],

              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,

                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.next,
                  obscureText: isPassword ? _obscure : false,
                  autocorrect: !isPassword,
                  enableSuggestions: !isPassword,
                  enabled: widget.enabled,

                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() {
                        _errorText = null;
                        _hasError = false;
                      });
                    }
                  },

                  inputFormatters: [
                    if (isPhone)
                      FilteringTextInputFormatter.digitsOnly,
                    if (isPhone)
                      LengthLimitingTextInputFormatter(10),
                  ],

                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 15),

                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,

                    hintStyle: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),

                    errorStyle: const TextStyle(
                      height: 0,
                      fontSize: 0,
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

        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 6,
            ),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }
}