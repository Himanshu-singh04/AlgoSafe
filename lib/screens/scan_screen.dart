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
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  int mainScreen = 0;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, pretty_exception("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
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
        mainScreen = 1;
      });
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, pretty_exception("Stop Scan Error:", e),
          success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    setState(() {
      onStopPressed();
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

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
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
          onTap: onStopPressed,
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
          onTap: onScanPressed,
        ),
      );
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeviceScreen(device: d),
                settings: const RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .where((r) => r.device.name.startsWith("Algo"))
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
          ),
        )
        .toList();
  }

//------------------------------------------------------------------------------------------------------------------------//
  Widget mainScreenDisplay() {
    final Size size = MediaQuery.of(context).size;

    return Column(
      children: [
        SizedBox(
          height: size.height * 0.05,
        ),
        Align(alignment: Alignment.topCenter,child: Text("Hi, Drone Operator",style: TextStyle(fontSize: size.width * 0.05),)),
        Align(alignment: Alignment.topCenter,child: Text("Connect to AlgoFET Devices", style: TextStyle(fontSize: size.width * 0.025))),
      ],
    );
  }
//------------------------------------------------------------------------------------------------------------------------//

  Widget scanScreenDisplay() {
    final Size size = MediaQuery.of(context).size;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          SizedBox(
          height: size.height * 0.05,
        ),
          Align(alignment: Alignment.topCenter,child: Text("Hi, Drone Operator", style: TextStyle(fontSize: size.width * 0.05))),
          Align(alignment: Alignment.topCenter,child: Text("Connect to AlgoFET Devices", style: TextStyle(fontSize: size.width * 0.025))),
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
                  child: Lottie.asset("assets/gifs/back.json",width: 50),
                  onTap: (){setState(() {
                        mainScreen = 0;
                        onStopPressed();
                      });},
                ),
                // IconButton(
                //     onPressed: () {
                //       setState(() {
                //         mainScreen = 0;
                //         onStopPressed();
                //       });
                //     },
                //     icon: const Icon(Icons.arrow_back)),
                SizedBox(
                  width: size.width * 0.02,
                )
              ],
              leading: Builder(
                builder: (context) => InkWell(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Lottie.asset("assets/gifs/drawer.json",width: 50)),
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
                      // leading: Icon(Icons.home),
                      title: Text("AlgoDOCK"),
                    ),
                    ListTile(
                      // leading: Icon(Icons.home),
                      title: Text("AlgoBMS"),
                    ),
                    ListTile(
                      // leading: Icon(Icons.home),
                      title: Text("AlgoX"),
                    ),
                    ListTile(
                      // leading: Icon(Icons.home),
                      title: Text("AlgoPACK"),
                    ),
                    ListTile(
                      // leading: Icon(Icons.home),
                      title: Text("AlgoSAFE"),
                    ),
                    ListTile(
                      // leading: Icon(Icons.home),
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
                      // leading: Icon(Icons.home),
                      title: Text("NEWS"),
                    ),
                    ListTile(
                      // leading: Icon(Icons.home),
                      title: Text("Partners"),
                    ),
                    ListTile(
                      // leading: Icon(Icons.home),
                      title: Text("FAQs"),
                    )
                  ],
                ),
                const Divider()
              ],
            ),
            // child: Column(

            // children: [
            // SizedBox(height: size.height*0.05,),
            // Container(child: Image.asset("assets/images/Algofet secondary subtext.png"),padding: EdgeInsets.all(size.width*0.075),)
            // ],
            // ),
          ),
          body: (mainScreen != 1) ? mainScreenDisplay() : scanScreenDisplay(),
          // body: RefreshIndicator(
          //   onRefresh: onRefresh,
          //   child: ListView(
          //     children: <Widget>[
          //       ..._buildSystemDeviceTiles(context),
          //       ..._buildScanResultTiles(context),
          //     ],
          //   ),
          // ),
          floatingActionButton: buildScanButton(context),
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
