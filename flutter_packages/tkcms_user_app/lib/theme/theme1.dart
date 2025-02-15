import 'package:flutter/material.dart';

const colorBlue = Colors.blue;
const colorBlueSelected = Color(0xff1b2177);
const colorWhite = Colors.white;
const colorError = Colors.red;
const colorGrey = Colors.grey;

/// Dark theme
ThemeData themeData1({TextTheme? textTheme}) {
  var themeData = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: colorBlue,
      brightness: Brightness.dark,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
  textTheme ??= themeData.textTheme;

  themeData = themeData.copyWith(
    snackBarTheme: SnackBarThemeData(
      actionTextColor: colorWhite,
      contentTextStyle: textTheme.bodyMedium,
      backgroundColor: colorBlue,
      //contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      elevation: 20,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(borderSide: BorderSide(color: colorBlue)),
    ),
    textTheme: textTheme.copyWith(
      labelSmall: const TextStyle(color: colorBlue),
    ),
    dividerTheme: const DividerThemeData(
      color: colorGrey,
      //thickness: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),

        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        backgroundColor: colorBlue, // Button color
        foregroundColor: colorWhite,
      ),
    ),
  );
  return themeData;
}
