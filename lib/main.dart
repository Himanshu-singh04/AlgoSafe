import 'dart:async';

import 'package:algo_safe/screens/firmware_update_screen.dart';
import 'package:algo_safe/screens/permission_screen.dart';
import 'package:algo_safe/screens/scan_drawer_screen.dart';
import 'package:algo_safe/screens/splash_screen.dart';
import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() async {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: splash_screen(),
  ));
}

// ignore: camel_case_types
class home_page extends StatefulWidget {
  const home_page({super.key});

  @override
  State<home_page> createState() => _home_pageState();
}

// ignore: camel_case_types
class _home_pageState extends State<home_page> {
  // status of the bluetooth permission and its state of on/off
  BluetoothAdapterState adapter_state = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> adapter_state_state_subscription;

  // gets the current bluetooth state  
  @override
  void initState() {
    super.initState();
    adapter_state_state_subscription = FlutterBluePlus.adapterState.listen((state) {
      adapter_state = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    adapter_state_state_subscription.cancel();
    super.dispose();
  }

  // building the main.dart activities
  // based on the adapter state it selects between scan+drawer and BluetoothoffScreen
  @override
  Widget build(BuildContext context) {
    Widget screen = adapter_state == BluetoothAdapterState.on
        ? firmware_Update()
        : BluetoothOffScreen(adapter_state: adapter_state);

    return MaterialApp(
      home: screen,
      navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}

class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  // Navigation and routes with a back sign/icon
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

  // Navigation and routes without a back sign/icon
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}

