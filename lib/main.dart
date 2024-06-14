import 'package:algosafe/screens/splash_screen.dart';
import 'package:algosafe/utils/theme_service.dart';
import 'package:algosafe/widgets/bottom_nav_bar.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:algosafe/controllers/ble_controller.dart';
import 'package:algosafe/controllers/permission_checker.dart';
import 'package:algosafe/screens/display_page.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeService = await ThemeService.instance;
  var initTheme = themeService.initial;
  runApp(MaterialApp(
    theme: initTheme,
    home: splash_screen(),
  ));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.theme});

  final ThemeData theme;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  bool _isBluetoothOn = false;
  Location location = Location();

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    // _toggleLocation();
  }

  Future<void> _toggleLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    var permissionGranted = await location.serviceEnabled();
    // ignore: unrelated_type_equality_checks
    if (permissionGranted == Permission.location.status.isDenied) {
      permissionGranted = (await location.requestPermission()) as bool;
      // ignore: unrelated_type_equality_checks
      if (permissionGranted != Permission.location.status.isGranted) {
        return;
      }
    }
  }

  void _checkBluetoothState() {
    flutterBlue.state.listen((state) {
      setState(() {
        _isBluetoothOn = state == BluetoothState.on;
      });
    });
  }

  void _toggleBluetooth() {
    if (_isBluetoothOn) {
      return;
    }

    BluetoothEnable.enableBluetooth.then((results) {
      if (results == "true") {
        setState(() {
          _isBluetoothOn = true;
        });
      } else if (results == "false") {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ThemeProvider(
          initTheme: ThemeData.light(),
          builder: (_, theme) {
            return ThemeSwitchingArea(
              child: Scaffold(
                  appBar: AppBar(
                    title: Container(
                      child: Image.asset("assets/images/Algofet primary subtext name.png"),
                    ),
                    actions: [IconButton(
                          onPressed: () {
                            checkPermission(Permission.location, context);
                                  //checkPermission(
                                      //Permission.bluetoothConnect, context);
                            _toggleLocation();
                          },
                          icon: Icon(Icons.pin_drop)),
                      IconButton(
                          onPressed: () {
                            //checkPermission(Permission.location, context);
                                  checkPermission(
                                      Permission.bluetoothConnect, context);
                            _toggleBluetooth();
                          },
                          icon: Icon(Icons.bluetooth)),
                      ThemeSwitcher(builder: (context) {
                        bool isDarkmode = ThemeModelInheritedNotifier.of(context)
                                .theme
                                .brightness ==
                            Brightness.light;
                        String themeName = isDarkmode ? 'Dark' : 'Light';
                        return DayNightSwitcherIcon(
                            isDarkModeEnabled: isDarkmode,
                            onStateChanged: (bool darkMode) async {
                              var service = await ThemeService.instance
                                ..save(darkMode ? 'Light' : 'Dark');
                              var theme = service.getByName(themeName);
                              ThemeSwitcher.of(context).changeTheme(
                                  theme: theme, isReversed: darkMode);
                            });
                      }),
                      SizedBox(width: 16,)
                    ],
                  ),
                  body: GetBuilder<BleController>(
                      init: BleController(),
                      builder: (BleController controller) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StreamBuilder<List<ScanResult>>(
                                  stream: controller.scanResults,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Expanded(
                                        child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (context, index) {
                                              final data = snapshot.data![index];
                                              return Card(
                                                elevation: 2,
                                                child: ListTile(
                                                  title: Text(data.device.name),
                                                  subtitle: Text(data.device.id.id),
                                                  trailing:
                                                      Text(data.rssi.toString()),
                                                  onTap: () {
                                                    controller.connectToDevice(
                                                        data.device);
                                                    Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                display_page(
                                                                  device:
                                                                      data.device,
                                                                  isConnected: true,
                                                                )));
                                                  },
                                                ),
                                              );
                                            }),
                                      );
                                    } else {
                                      return const Center(
                                        child: Text("No Device Found"),
                                      );
                                    }
                                  }),
                              const SizedBox(
                                height: 10,
                              ),
                            
                                  Stack(
                                    children: [bottom_nav_bar(),
                                    Center(
                                      child: IconButton(onPressed: () async {
                                        controller.scanDevices();
                                      }, icon: Icon(Icons.scanner_rounded)),
                                    )
                                      //Center(
                                      //                              child: ElevatedButton(
                                      //style: ElevatedButton.styleFrom(minimumSize: Size(size.width*0.01, size.height*0.05),backgroundColor: Colors.orange),
                                      //  onPressed: () async {
                                      //    controller.scanDevices();
                                      //  },
                                      //  child:
                                      //     IconButton(onPressed: (){}, icon: Icon(Icons.info)),
                                      //    ),
                                      //                            ),
                                                                  
                                    ],
                                  ),
                              
                                
                            ],
                          ),
                        );
                      },
                    ),
                  
                  // bottomNavigationBar: const bottom_nav_bar()
                  )
            );
          }),
    );
  }
}
