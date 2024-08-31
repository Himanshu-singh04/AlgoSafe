import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:algo_safe/screens/device_screen.dart';
import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/extra.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:algo_safe/widgets/scan_result_tile.dart';
import 'package:algo_safe/widgets/system_device_tile.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class firmware_Update extends StatefulWidget {
  const firmware_Update({super.key});

  @override
  State<firmware_Update> createState() => _firmware_UpdateState();
}

class _firmware_UpdateState extends State<firmware_Update> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  int mainScreen = 0;

  Future<bool> request_per(Permission permission) async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;

    if (build.version.sdkInt >= 30) {
      var re = await Permission.manageExternalStorage.request();
      if (re.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      if (await permission.isGranted) {
        return true;
      } else {
        var result = await permission.request();
        if (result.isGranted) {
          return true;
        } else {
          return false;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      // Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
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
      // Snackbar.show(ABC.b, prettyException("System Devices Error:", e),
      //     success: false);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      // Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
      //     success: false);
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
      // Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e),
      //     success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) async {
    setState(() {
      onStopPressed();
    });
    device.connect_and_update_stream().catchError((e) {
      // Snackbar.show(ABC.c, prettyException("Connect Error:", e),
      //     success: false);
    });
    if (await request_per(Permission.storage)) {
    print("Permission granted");

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String filePath = result.files.single.path!;
      File file = File(filePath);
      if (file.existsSync()) {
        var fileContents = await file.readAsBytes();
        // String fileContents = await file.readAsString();
        // Convert fileContents (hex string) to Uint8List (byte array)
        // Uint8List data = Uint8List.fromList(fileContents.codeUnits);
        Uint8List data = Uint8List.fromList(fileContents);

        // Send data over BLE
        await sendFileOverBLE(device, data);
      } else {
        print("File does not exist");
      }
    } else {
      // User canceled the file picker
      print("User canceled file picking");
    }
  } else {
    print("Permission not granted");
  }
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          child: SizedBox(
            height: size.height * 0.05,
            child: Icon(Icons.arrow_back),
          ),
          onTap: onStopPressed,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: CustomColors.mainColor_1,
          borderRadius: BorderRadius.circular(20),
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
        .where((r) => r.device.name.startsWith(""))
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
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
      onRefresh: onRefresh,
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

  Future<void> sendFileOverBLE(BluetoothDevice device, Uint8List data) async {
  // Connect to the selected device
  await device.connect();

  // Discover services and characteristics
  List<BluetoothService> services = await device.discoverServices();
  BluetoothCharacteristic? characteristic;

  // Replace with your characteristic UUID
  String characteristicUuid = "eb67b8e6-eaa9-411a-9de2-534fb9263c71";

  for (BluetoothService service in services) {
    for (BluetoothCharacteristic c in service.characteristics) {
      if (c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
        characteristic = c;
        break;
      }
    }
    if (characteristic != null) {
      break;
    }
  }

  // Check if characteristic was found
  if (characteristic == null) {
    print('Write characteristic not found');
    return;
  }

  // Calculate chunk size and send data in chunks
  int chunkSize = 4; // Adjust chunk size as per your requirement
  int dataLength = data.length;
  int offset = 0;

  while (offset < dataLength) {
    int end = (offset + chunkSize < dataLength) ? offset + chunkSize : dataLength;
    Uint8List chunk = data.sublist(offset, end);
    await characteristic.write(chunk);
    print(data);
    print("Sent chunk ${offset ~/ chunkSize + 1} of ${dataLength ~/ chunkSize}");
    offset += chunkSize;
    await Future.delayed(Duration(milliseconds: 100)); // Optional delay between chunks
  }

  print("File sent successfully");

  // Disconnect from device
  await device.disconnect();
}

  Future<String> preprocessHexFile(String filePath) async {
    File file = File(filePath);
    List<String> lines = await file.readAsLines();
    
    // Step 1: Modify the original file
    List<String> modifiedLines = [];
    for (String line in lines) {
      if (line.startsWith(':')) {
        line = ':' + line.substring(9, line.length - 3);
      }
      modifiedLines.add(line);
    }
    
    // Step 2: Remove first and last lines, and combine remaining lines
    modifiedLines = modifiedLines.sublist(1, modifiedLines.length - 2);
    String combinedLine = modifiedLines.join().replaceAll(':', '');
    
    return combinedLine;
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
                      mainScreen = 0;
                      onStopPressed();
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
          body: (mainScreen != 1) ? main_screen_display() : scan_screen_display(),
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