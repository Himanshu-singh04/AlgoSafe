import 'dart:async';

import 'package:algo_safe/screens/login_screen.dart';
import 'package:algo_safe/screens/permission_screen.dart';
import 'package:algo_safe/screens/scan_drawer_screen.dart';
import 'package:algo_safe/screens/splash_screen.dart';
import 'package:algo_safe/screens/wrapper.dart';
// import 'package:algo_safe/screens/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    home: splash_screen(),
    // home: wrapper(),
    routes: {
      '/permissions': (context) => BluetoothOffScreen(),
      '/login': (context) => LoginScreen(),
      '/home': (context) => HomePage(),
      '/wrapper': (context) => wrapper() 
    },
  ));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothAdapterState adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    adapterStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen = adapterState == BluetoothAdapterState.on
        ? scan_drawer()
        : BluetoothOffScreen(adapter_state: adapterState);

    return MaterialApp(
      home: screen,
      navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}

class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') {
      _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}