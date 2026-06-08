import 'package:flutter/material.dart';

import 'home.dart';
import 'login.dart';
import 'profile_setup_page.dart';
import 'refrigerator_home_page.dart';
import 'machine_home_page.dart';
import 'machine_detail_page.dart';
import 'admin_home_page.dart';
import 'admin_my_page.dart';
import 'student_my_page.dart';
import 'notification_page.dart';
import 'refrigerator_camera_page.dart';
import 'qr_scan_page.dart';

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
        '/refrigeratorHome': (context) => const RefrigeratorHomePage(),
        '/machineHome': (context) => const MachineHomePage(),
        '/machineDetail': (context) => const MachineDetailPage(),
        '/studentMy': (context) => const StudentMyPage(),
        '/adminMy': (context) => const AdminMyPage(),
        '/adminHome': (context) => const AdminHomePage(),
        '/notificationPage': (context) => const NotificationPage(),
        '/refrigeratorCamera': (context) => const RefrigeratorCameraPage(),
        '/qrScan': (context) => const QRScanPage(),
      },
    );
  }
}
