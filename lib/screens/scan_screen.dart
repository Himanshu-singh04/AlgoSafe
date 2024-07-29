import 'dart:async';

import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';

import 'device_screen.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../utils/extra.dart';

// ignore: must_be_immutable
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
    final Size size = MediaQuery.of(context).size;

    if (FlutterBluePlus.isScanningNow) {
      return Container(
        decoration: BoxDecoration(
          color: CustomColors.mainColor_1,
          borderRadius:
              BorderRadius.circular(20), // Adjust the radius as needed
        ),
        child: InkWell(
          child: SizedBox(
            height: size.height * 0.05,
            child: Lottie.asset("assets/gifs/stop_scan.json"),
          ),
          onTap: on_stop_pressed,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: CustomColors.mainColor_1,
          borderRadius:
              BorderRadius.circular(20), // Adjust the radius as needed
        ),
        child: InkWell(
          child: SizedBox(
              height: size.height * 0.05,
              child: Lottie.asset("assets/gifs/scan.json")),
          onTap: on_scan_pressed,
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
              style: TextStyle(fontSize: size.width * 0.05),
            )),
        Align(
            alignment: Alignment.topCenter,
            child: Text("Connect to AlgoFET Devices",
                style: TextStyle(fontSize: size.width * 0.025))),
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
                  style: TextStyle(fontSize: size.width * 0.05))),
          Align(
              alignment: Alignment.topCenter,
              child: Text("Connect to AlgoFET Devices",
                  style: TextStyle(fontSize: size.width * 0.025))),
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              backgroundColor: Colors.white,
              toolbarHeight: size.height * 0.05,
              flexibleSpace: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: Container(
                  color: CustomColors.mainColor_1,
                ),
              ),
              title: Image.asset(
                "assets/images/Algofet primary subtext_white_copy.png",
                width: size.width * 0.40,
              ),
              actions: [
                InkWell(
                  child: Lottie.asset("assets/gifs/back.json", width: 50),
                  onTap: () {
                    setState(() {
                      main_screen = 0;
                      on_stop_pressed();
                    });
                  },
                ),
                SizedBox(
                  width: size.width * 0.02,
                )
              ],
              leading: Builder(
                builder: (context) => InkWell(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Lottie.asset("assets/gifs/drawer.json", width: 50)),
              )),
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  child: Image.asset(
                      "assets/images/Algofet secondary subtext.png"),
                  padding: EdgeInsets.all(size.width * 0.02),
                ),
                const ListTile(
                  leading: Icon(Icons.home),
                  title: Text("Home"),
                ),
                const Divider(),
                const ExpansionTile(
                  leading: Icon(Icons.shopping_bag_rounded),
                  title: Text("Products"),
                  children: [
                    ListTile(
                      title: Text("AlgoDOCK"),
                    ),
                    ListTile(
                      title: Text("AlgoBMS"),
                    ),
                    ListTile(
                      title: Text("AlgoX"),
                    ),
                    ListTile(
                      title: Text("AlgoPACK"),
                    ),
                    ListTile(
                      title: Text("AlgoSAFE"),
                    ),
                    ListTile(
                      title: Text("AlgoCOM"),
                    ),
                  ],
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.person_3),
                  title: Text("Application"),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.call),
                  title: Text("Contact Us"),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.work),
                  title: Text("Company"),
                ),
                const Divider(),
                const ExpansionTile(
                  leading: Icon(Icons.more),
                  title: Text("More"),
                  children: [
                    ListTile(
                      title: Text("NEWS"),
                    ),
                    ListTile(
                      title: Text("Partners"),
                    ),
                    ListTile(
                      title: Text("FAQs"),
                    )
                  ],
                ),
                const Divider()
              ],
            ),
          ),
          body: (main_screen != 1)
              ? main_screen_display()
              : scan_screen_display(),
          floatingActionButton: build_scan_button(context),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: CurvedNavigationBar(
              height: 60,
              color: CustomColors.mainColor_1,
              backgroundColor: Colors.white,
              items: [
                Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                Icon(
                  Icons.person,
                  color: Colors.white,
                ),
                Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                ),
                Icon(
                  Icons.settings,
                  color: Colors.white,
                )
              ])),
    );
  }
}
