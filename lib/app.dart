import 'package:flutter/material.dart';

import 'home.dart';
import 'login.dart';
import 'profile_setup_page.dart';

class ShrineApp extends StatelessWidget {
  const ShrineApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DormSync',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profileSetup': (context) => const ProfileSetupPage(),
      },
    );
  }
}
