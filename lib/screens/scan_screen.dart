import 'dart:async';

import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../utils/extra.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> system_devices = [];
  List<ScanResult> scan_results = [];
  bool is_scanning = false;
  late StreamSubscription<List<ScanResult>> scan_results_subscription;
  late StreamSubscription<bool> is_scanning_subscription;
  int main_screen = 0;
  int _selectedIndex = 0;

  double x_offset = 0;
  double y_offset = 0;
  double scale_factor = 1;
  bool is_drawer_open = false;

  @override
  void initState() {
    super.initState();

    scan_results_subscription = FlutterBluePlus.scanResults.listen((results) {
      scan_results = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, pretty_exception("Scan Error:", e), success: false);
    });

    is_scanning_subscription = FlutterBluePlus.isScanning.listen((state) {
      is_scanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    scan_results_subscription.cancel();
    is_scanning_subscription.cancel();
    super.dispose();
  }

  Future on_scan_pressed() async {
    try {
      system_devices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      Snackbar.show(ABC.b, pretty_exception("System Devices Error:", e),
          success: false);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      Snackbar.show(ABC.b, pretty_exception("Start Scan Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        main_screen = 1;
      });
    }
  }

  Future on_stop_pressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, pretty_exception("Stop Scan Error:", e),
          success: false);
    }
  }

  void on_connect_pressed(BluetoothDevice device) {
    setState(() {
      on_stop_pressed();
    });
    device.connect_and_update_stream().catchError((e) {
      Snackbar.show(ABC.c, pretty_exception("Connect Error:", e),
          success: false);
    });
    MaterialPageRoute route = MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device),
        settings: const RouteSettings(name: '/DeviceScreen'));
    Navigator.of(context).push(route);
  }

  Future on_refresh() {
    if (is_scanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget build_scan_button(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return Container(
        decoration: BoxDecoration(
          color: CustomColors.mainColor_1,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: CustomColors.mainColor_1,
          label: SizedBox(
            child: Text(
              "Stop Scanning",
              style: TextStyle(color: Colors.white),
            ),
          ),
          onPressed: on_stop_pressed,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: CustomColors.mainColor_1,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: CustomColors.mainColor_1,
          label: SizedBox(
            child: Text(
              "Scan for Devices",
              style: TextStyle(color: Colors.white),
            ),
          ),
          onPressed: on_scan_pressed,
        ),
      );
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return system_devices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeviceScreen(device: d),
                settings: const RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () => on_connect_pressed(d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return scan_results
        .where((r) => r.device.name.startsWith("Algo"))
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => on_connect_pressed(r.device),
          ),
        )
        .toList();
  }

  Widget main_screen_display() {
    final Size size = MediaQuery.of(context).size;

    return Column(
      children: [
        SizedBox(
          height: size.height * 0.05,
        ),
        Align(
            alignment: Alignment.topCenter,
            child: Text(
              "Hi, Drone Operator",
              style: TextStyle(fontSize: size.width * 0.075),
            )),
        Align(
            alignment: Alignment.topCenter,
            child: Text("Connect to AlgoFET Devices",
                style: TextStyle(fontSize: size.width * 0.04))),
      ],
    );
  }

  Widget scan_screen_display() {
    final Size size = MediaQuery.of(context).size;
    return RefreshIndicator(
      onRefresh: on_refresh,
      child: Column(
        children: [
          SizedBox(
            height: size.height * 0.05,
          ),
          Align(
              alignment: Alignment.topCenter,
              child: Text("Hi, Drone Operator",
                  style: TextStyle(fontSize: size.width * 0.075))),
          Align(
              alignment: Alignment.topCenter,
              child: Text("Connect to AlgoFET Devices",
                  style: TextStyle(fontSize: size.width * 0.04))),
          Expanded(
            child: ListView(
              children: <Widget>[
                ..._buildSystemDeviceTiles(context),
                ..._buildScanResultTiles(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: AnimatedContainer(
        transform: Matrix4.translationValues(x_offset, y_offset, 0)
          ..scale(scale_factor),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(is_drawer_open ? 40 : 0),
          color: Colors.white,
        ),
        duration: Duration(milliseconds: 250),
        child: Container(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CustomColors.mainColor_1,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: size.height * 0.05,
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: size.width * 0.05,
                        ),
                        is_drawer_open
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    x_offset = 0;
                                    y_offset = 0;
                                    scale_factor = 1;
                                    is_drawer_open = false;
                                  });
                                },
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                ))
                            : IconButton(
                                onPressed: () {
                                  setState(() {
                                    x_offset = size.height * 0.25;
                                    y_offset = size.width * 0.57;
                                    scale_factor = 0.55;
                                    is_drawer_open = true;
                                  });
                                },
                                icon: Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                )),
                        Spacer(),
                        IconButton(
                            onPressed: () {
                              setState(() {
                                main_screen = 0;
                                on_stop_pressed();
                              });
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            )),
                        SizedBox(
                          width: size.width * 0.01,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: size.height * 0.01,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: (main_screen != 1)
                    ? main_screen_display()
                    : scan_screen_display(),
              ),
              build_scan_button(context),
              SizedBox(
                height: size.height * 0.01,
              ),
              Stack(children: [
                Container(
                  color: Colors.white,
                  height: size.height * 0.1,
                ),
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CustomColors.mainColor_3,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(70))
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: size.width * 0.9,
                            child: BottomNavigationBar(
                              elevation: 0,
                              items: const <BottomNavigationBarItem>[
                                BottomNavigationBarItem(
                                  icon: Icon(Icons.search),
                                  label: 'Search',
                                ),
                                BottomNavigationBarItem(
                                  icon: Icon(Icons.person),
                                  label: 'Profile',
                                ),
                                BottomNavigationBarItem(
                                  icon: Icon(Icons.settings),
                                  label: 'Setting',
                                ),
                              ],
                              currentIndex: _selectedIndex,
                              selectedItemColor: Colors.black,
                              unselectedItemColor: Colors.white,
                              onTap: _onItemTapped,
                              backgroundColor: Colors.transparent,
                              type: BottomNavigationBarType.fixed,
                              showSelectedLabels: true,
                              showUnselectedLabels: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  height: size.height * 0.1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(70),
                    ),
                    color: CustomColors.mainColor_1,
                  ),
                ),
              ])
            ],
          ),
        ),
      ),
    );
  }
}