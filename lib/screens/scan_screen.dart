import 'dart:async';

import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
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
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e),
          success: false);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
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
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e),
          success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    setState(() {
      onStopPressed();
    });
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e),
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
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton.extended(
        label: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton.extended(
          backgroundColor: CustomColors.mainColor_3,
          label: const Text(
            "SCAN",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: onScanPressed);
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
    return Container();
  }
//------------------------------------------------------------------------------------------------------------------------//

  Widget scanScreenDisplay() {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: <Widget>[
          ..._buildSystemDeviceTiles(context),
          ..._buildScanResultTiles(context),
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
          appBar: AppBar(
            //systemOverlayStyle: SystemUiOverlayStyle.dark
            //    .copyWith(statusBarColor: Colors.black),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade500],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)),
            ),
            title: Image.asset(
              "assets/images/Algofet primary subtext name.png",
              width: size.width * 0.60,
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      mainScreen = 0;
                      onStopPressed();
                    });
                  },
                  icon: const Icon(Icons.arrow_back)),
              SizedBox(
                width: size.width * 0.02,
              )
            ],
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  child: Image.asset(
                      "assets/images/Algofet secondary subtext.png"),
                  padding: EdgeInsets.all(size.width * 0.075),
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
                    ),const Divider(),
                const ListTile(
                      leading: Icon(Icons.work),
                      title: Text("Company"),
                    ),const Divider(),
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
                      title: Text("Partners"),),
                      ListTile(
                      // leading: Icon(Icons.home),
                      title: Text("FAQs"),)
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
          bottomNavigationBar: Container(
            height: size.height * 0.075,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade500],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter)),
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade500],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)),
              child: Padding(
                padding: EdgeInsets.all(NavigationToolbar.kMiddleSpacing),
                child: GNav(
                    padding: EdgeInsets.all(BorderSide.strokeAlignCenter),
                    // backgroundColor: Colors.grey,
                    activeColor: Colors.white,
                    tabBackgroundColor: Colors.black38,
                    gap: 8,
                
                    tabs: [
                      GButton(
                        icon: Icons.search,
                        text: "Scan",
                        // onPressed: (){}
                      ),
                      GButton(
                        icon: Icons.settings,
                        text: "Setting",
                      ),
                      GButton(
                        icon: Icons.light,
                        text: "Light",
                      ),
                      GButton(
                        icon: Icons.book,
                        text: "Book",
                      )
                    ]),
              ),
            ),
          )),
    );
  }
}
