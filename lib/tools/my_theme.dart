import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xffeebb02),
  primarySwatch: Colors.blueGrey,
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  // baseColor: Color(0xFF3E3E3E),
  // lightSource: LightSource.topLeft,
  textTheme: TextTheme(),
  // depth: 6,
);
