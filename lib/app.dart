import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainMenuScreen(),
    );
  }
}

