import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Memory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F4EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF53736A),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFCF7),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'SF Pro Display',
          bodyColor: const Color(0xFF262626),
          displayColor: const Color(0xFF1D1D1F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F4EE),
          foregroundColor: Color(0xFF1D1D1F),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFCF7),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE7E0D6)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
