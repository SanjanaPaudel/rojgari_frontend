import 'package:flutter/material.dart';
import 'package:rojgari_frontend_one/core/constants/colors.dart';

class PasswordRequirement extends StatelessWidget {
  final String text; //Stores the text like "At least 8 character" that we pass to this class.
  final bool isValid; //tells if the requirement written in the text variable is fulfilled or not true -> fulfilled, false -> not fulfilled.

  const PasswordRequirement({ //constructor
    super.key,
    required this.text,
    required this.isValid,
    // Since text and isValid is required Whenever someone creates this widget, they must provide text and isValid.
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250), // time given for animation
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: isValid    //if isValid is true use green color else use light purple color
                  ? AppColors.green
                  : AppColors.lightPurple,
              shape: BoxShape.circle,
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                isValid ? Icons.check : Icons.circle_outlined,
                color: isValid ? Colors.white : AppColors.grey,
              ),
            ),
          ),

          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isValid
                  ? AppColors.green
                  : AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}