import 'package:algo_safe/screens/scan_screen.dart';
import 'package:algo_safe/screens/drawer_screen.dart';
import 'package:flutter/material.dart';

class scan_drawer extends StatefulWidget {
  const scan_drawer({super.key});

  @override
  State<scan_drawer> createState() => _scan_drawerState();
}

class _scan_drawerState extends State<scan_drawer> {
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          drawer_screen(),
          ScanScreen(),
        ],
      ),
    );
  }
}