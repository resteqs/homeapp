import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFD8E9A8),
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: const Color(0xFF1E5128),
    primary: const Color(0xFF1E5128),
    secondary: const Color(0xFF4E9F3D),
    tertiary: const Color(0xFF191A19),
    surface: const Color(0xFFD8E9A8),
    onSurface: const Color(0xFF191A19),
    onPrimary: const Color(0xFFD8E9A8),
  ),
  textTheme: const TextTheme().apply(
    bodyColor: const Color(0xFF191A19),
    displayColor: const Color(0xFF191A19),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFD8E9A8),
    foregroundColor: Color(0xFF191A19),
    elevation: 0,
  ),
);

@NowaGenerated()
final ThemeData darkTheme = lightTheme;
