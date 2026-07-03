import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {

  static ThemeData lightTheme=ThemeData(

      scaffoldBackgroundColor: AppColors.background,

      fontFamily:'Poppins',

      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation:0
      )

  );

}