import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFEDF1D6),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF609966),
    primary: const Color(0xFF609966),
    secondary: const Color(0xFF9DC08B),
    surface: Colors.white, // White cards on EDF1D6 background
    onSurface: const Color(0xFF40513B),
    onPrimary: Colors.white,
  ),
  textTheme: const TextTheme().apply(
    bodyColor: const Color(0xFF40513B),
    displayColor: const Color(0xFF40513B),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEDF1D6),
    foregroundColor: Color(0xFF40513B),
    elevation: 0,
  ),
);

@NowaGenerated()
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color(0xFF609966),
    primary: const Color(0xFF9DC08B),
    secondary: const Color(0xFF609966),
    surface: const Color(0xFF40513B),
    onSurface: const Color(0xFFEDF1D6),
  ),
  textTheme: const TextTheme().apply(
    bodyColor: const Color(0xFFEDF1D6),
    displayColor: const Color(0xFFEDF1D6),
  ),
);
