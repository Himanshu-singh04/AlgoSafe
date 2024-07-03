import 'dart:async';
import 'dart:typed_data';
import 'package:algo_safe/constants/uuid_list.dart';
import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widgets/service_tile.dart';
import '../widgets/characteristic_tile.dart';
import '../widgets/descriptor_tile.dart';
import '../utils/extra.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  var _currentBmsState = 0; // 0: idle, 1: charging, 2:discharging

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;
  int _selectedIndex = 0;

  Map<String, String> data = {};
  // final TextEditingController _writeController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {
    for (var key in uuids.keys) key: TextEditingController()
  };

  void _delayedRefreshFunction() {
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        onRefreshPressed();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _delayedRefreshFunction();

    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    _mtuSubscription = widget.device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription =
        widget.device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future onConnectPressed() async {
    try {
      await widget.device.connectAndUpdateStream();
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e),
            success: false);
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream();
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e),
          success: false);
    }
  }

  Future onRefreshPressed() async {
    try {
      _isDiscoveringServices = true;
      setState(() {});
      _services = await widget.device.discoverServices();
      for (var service in _services) {
        for (var characteristic in service.characteristics) {
          if (uuids.containsValue(characteristic.uuid.toString())) {
            subscribeToCharacteristic(characteristic);
          }
        }
      }
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await widget.device.requestMtu(223, predelay: 0);
      Snackbar.show(ABC.c, "Request Mtu: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Change Mtu Error:", e),
          success: false);
    }
  }

  List<Widget> _buildServiceTiles(BuildContext context, BluetoothDevice d) {
    return _services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map((c) => _buildCharacteristicTile(c))
                .toList(),
          ),
        )
        .toList();
  }

  CharacteristicTile _buildCharacteristicTile(BluetoothCharacteristic c) {
    return CharacteristicTile(
      characteristic: c,
      descriptorTiles:
          c.descriptors.map((d) => DescriptorTile(descriptor: d)).toList(),
      descriptors: [],
    );
  }

  Widget buildSpinner(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            '${widget.device.remoteId}',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const Spacer(),
        stateSelectorShow()
      ],
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''),
            style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      _services = await widget.device.discoverServices();
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        TextButton(
          onPressed: () {
            onDiscoverServicesPressed();
            _buildServiceTiles(context, widget.device);
          },
          child: const Text(
            "Get Services",
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  int parseUint16(List<int> value) {
    final ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));
    return byteData.getUint16(0, Endian.little);
  }

  Future<void> subscribeToCharacteristic(
      BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    characteristic.value.listen((value) {
      String characteristicKey = uuids.keys
          .firstWhere((key) => uuids[key] == characteristic.uuid.toString());

      if (value.isNotEmpty) {
        String parsedValue;
        if (value.length == 1) {
          // uint8 parsing
          parsedValue = value[0].toString();
        } else if (value.length >= 2) {
          // uint16 parsing
          parsedValue = parseUint16(value).toString();
        } else {
          parsedValue = 'Unknown value';
        }

        setState(() {
          data[characteristicKey] = parsedValue;
        });
      }
    });
  }

  Widget stateSelected() {
    var statevalue = data["BMS_state"];
    if (statevalue is String) {
      _currentBmsState = int.tryParse(statevalue) ?? 0;
    } else if (statevalue is int) {
      // ignore: cast_from_null_always_fails
      _currentBmsState = statevalue as int;
    } else {
      _currentBmsState = 0;
    }

    switch (_currentBmsState) {
      case 0:
        return idleWidget();

      case 1:
        return chargingWidget();

      case 2:
        return dischargingWidget();

      default:
        return idleWidget();
    }
  }

  Future writeCharacteristic(
      BluetoothCharacteristic characteristic, String value) async {
    List<int> bytes = value.codeUnits;
    await characteristic.write(bytes, withoutResponse: true);
  }

  Future<void> onWritePressed(String characteristicName) async {
    String? characteristicUuid = uuids[characteristicName];
    String value = _controllers[characteristicName]?.text ?? '';

    // Validate input values
    if (value.isEmpty || characteristicUuid == null) {
      Snackbar.show(
        ABC.c,
        "$characteristicName Write: No value provided or invalid UUID",
        success: false,
      );
      return; // Skip if no value is provided or UUID is invalid
    }

    BluetoothCharacteristic? targetCharacteristic;

    // Find the target characteristic by UUID
    for (var service in _services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == characteristicUuid) {
          targetCharacteristic = characteristic;
          break;
        }
      }
      if (targetCharacteristic != null) break;
    }

    if (targetCharacteristic != null) {
      try {
        // Check if the characteristic supports write without response
        if (targetCharacteristic.properties.writeWithoutResponse) {
          await targetCharacteristic.write(value.codeUnits,
              withoutResponse: true);
          Snackbar.show(ABC.c, "$characteristicName Write: Success",
              success: true);
        }
        // Check if the characteristic supports write with response
        else if (targetCharacteristic.properties.write) {
          await targetCharacteristic.write(value.codeUnits,
              withoutResponse: false);
          Snackbar.show(ABC.c, "$characteristicName Write: Success",
              success: true);
        }
        // Characteristic is not writable
        else {
          Snackbar.show(
            ABC.c,
            "$characteristicName Write: Characteristic not writable",
            success: false,
          );
        }
      } catch (e) {
        Snackbar.show(
          ABC.c,
          "$characteristicName Write: Error - $e",
          success: false,
        );
      }
    } else {
      Snackbar.show(
        ABC.c,
        "$characteristicName Write: Characteristic not found",
        success: false,
      );
    }
  }

  Widget writeScreen() {
    final Size size = MediaQuery.of(context).size;
    return Expanded(
      child: ListView(
        children: [
          buildDropdownForCharacteristic("Battery_configuration"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildSliderForCharacteristic("Battery_constant_current"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildSliderForCharacteristic("Battery_peak_current"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildSliderForCharacteristic("Battery_max_voltage"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildSliderForCharacteristic("Battery_min_voltage"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildSliderForCharacteristic("Battery_operating_temperature"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildTextFieldForCharacteristic("Battery_id"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildTextFieldForCharacteristic("BMS_id"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildToggleForCharacteristic("Battery_DSG_C"),
          SizedBox(
            height: size.height * 0.01,
          ),
          buildToggleForCharacteristic("Battery_CHG_C"),
          SizedBox(
            height: size.height * 0.01,
          ),
        ],
      ),
    );
  }

  Map<String, List<String>> dropdownItems = {
    "Battery_configuration": ["2", "4", "6", "8", "10", "12", "14", "16"],
  };

  Widget buildTextFieldForCharacteristic(String key) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.height * 0.01),
          color: CustomColors.mainColor_3),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: _controllers[key],
                decoration: InputDecoration(
                  labelText: key.replaceAll('_', ' '),
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              color: Colors.white,
              onPressed: () => onWritePressed(key),
              icon: Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDropdownForCharacteristic(String key) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.height * 0.01),
          color: CustomColors.mainColor_3),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _controllers[key]?.text.isEmpty == true
                    ? null
                    : _controllers[key]?.text,
                onChanged: (newValue) {
                  setState(() {
                    _controllers[key]?.text = newValue!;
                  });
                },
                items: dropdownItems[key]?.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: key.replaceAll('_', ' '),
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                iconEnabledColor: Colors.white,
                dropdownColor: CustomColors.mainColor_3,
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              color: Colors.white,
              onPressed: () => onWritePressed(key),
              icon: Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }

  final Map<String, double> _sliderValues = {
    "Battery_constant_current": 0.0,
    "Battery_peak_current": 0.0,
    "Battery_max_voltage": 0.0,
    "Battery_min_voltage": 0.0,
    "Battery_operating_temperature": 0.0,
  };

  Map<String, List<double>> sliderMinMax = {
    "Battery_constant_current": [0.0, 100.0],
    "Battery_peak_current": [0.0, 100.0],
    "Battery_max_voltage": [0.0, 100.0],
    "Battery_min_voltage": [0.0, 100.0],
    "Battery_operating_temperature": [0.0, 100.0],
  };

  Map<String, int> sliderDivisions = {
    "Battery_constant_current": 50,
    "Battery_peak_current": 50,
    "Battery_max_voltage": 50,
    "Battery_min_voltage": 50,
    "Battery_operating_temperature": 50,
  };

  Widget buildSliderForCharacteristic(String key) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.height * 0.01),
          color: CustomColors.mainColor_3),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${key}: ${_sliderValues[key]?.toStringAsFixed(1)}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            double newValue = _sliderValues[key]! - 1;
                            if (newValue >= sliderMinMax[key]![0]) {
                              _sliderValues[key] = newValue;
                              _controllers[key]?.text =
                                  newValue.toStringAsFixed(1);
                            }
                          });
                        },
                      ),
                      Slider(
                        activeColor: Colors.blueAccent,
                        value: _sliderValues[key] ?? 0.0,
                        min: sliderMinMax[key]?.first ?? 0.0,
                        max: sliderMinMax[key]?.last ?? 100.0,
                        divisions: sliderDivisions[key] ?? 10,
                        label:
                            (_sliderValues[key]?.toStringAsFixed(1) ?? '0.0'),
                        onChanged: (newValue) {
                          setState(() {
                            _sliderValues[key] = newValue;
                            _controllers[key]?.text =
                                newValue.toStringAsFixed(1);
                          });
                        },
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            double newValue = _sliderValues[key]! + 1;
                            if (newValue <= sliderMinMax[key]![1]) {
                              _sliderValues[key] = newValue;
                              _controllers[key]?.text =
                                  newValue.toStringAsFixed(1);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              color: Colors.white,
              onPressed: () => onWritePressed(key),
              icon: Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, bool> _toggleValues = {
    "Battery_DSG_C": false,
    "Battery_CHG_C": false,
  };

  Widget buildToggleForCharacteristic(String key) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.height * 0.01),
          color: CustomColors.mainColor_3),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    key.replaceAll('_', ' '),
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Switch(
                    activeColor: Colors.grey,
                    value: _toggleValues[key] ?? false,
                    onChanged: (bool newValue) {
                      setState(() {
                        _toggleValues[key] = newValue;
                        _controllers[key]?.text = newValue ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              color: Colors.white,
              onPressed: () => onWritePressed(key),
              icon: Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget stateSelectorShow() {
    final Size size = MediaQuery.of(context).size;
    var statevalue = data["BMS_state"];
    if (statevalue is String) {
      _currentBmsState = int.tryParse(statevalue) ?? 0;
    } else if (statevalue is int) {
      // ignore: cast_from_null_always_fails
      _currentBmsState = statevalue as int;
    } else {
      _currentBmsState = 0;
    }

    switch (_currentBmsState) {
      case 0: // Idle Mode
        return Container(
          height: size.height * 0.05,
          color: Colors.blue,
          child: Padding(
              padding: const EdgeInsets.all(4),
              child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.power_off),
                          Text(
                            "IDLE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    );
                  })),
        );

      case 1: // Charging Mode
        return Container(
          height: size.height * 0.05,
          color: Colors.green,
          child: Padding(
              padding: const EdgeInsets.all(4),
              child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.battery_charging_full),
                          Text(
                            "CHARGE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    );
                  })),
        );

      case 2: // Discharging Mode
        return Container(
          height: size.height * 0.05,
          color: Colors.red,
          child: Padding(
              padding: const EdgeInsets.all(4),
              child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.battery_alert_sharp),
                          Text(
                            "DISCHARGE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    );
                  })),
        );
      default:
        return Container(
          height: size.height * 0.05,
          color: Colors.blue,
          child: Padding(
              padding: const EdgeInsets.all(4),
              child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.power_off),
                          Text(
                            "IDLE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    );
                  })),
        );
    }
  }

  Widget navShow() {
    final Size size = MediaQuery.of(context).size;
    var navValue = data["BMS_state"];
    if (navValue is String) {
      _currentBmsState = int.tryParse(navValue) ?? 0;
    } else if (navValue is int) {
      // ignore: cast_from_null_always_fails
      _currentBmsState = navValue as int;
    } else {
      _currentBmsState = 0;
    }

    switch (_currentBmsState) {
      case 0:
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade500],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
          child: NavigationBar(
            indicatorColor: Colors.black12,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            height: size.height * 0.075,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: <NavigationDestination>[
              NavigationDestination(
                  icon: Icon(Icons.my_library_books), label: "Data Monitoring"),
              NavigationDestination(
                  icon: Icon(Icons.edit), label: "Data Configuration")
            ],
          ),
        );

      case 1:
        return SizedBox.shrink();

      case 2:
        return SizedBox.shrink();

      default:
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade500],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
          child: NavigationBar(
            indicatorColor: Colors.black12,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            height: size.height * 0.075,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: <NavigationDestination>[
              NavigationDestination(
                  icon: Icon(Icons.my_library_books), label: "Data Monitoring"),
              NavigationDestination(
                  icon: Icon(Icons.edit), label: "Data Configuration")
            ],
          ),
        );
    }
  }

  Widget buildDisplayData(BuildContext context) {
    BluetoothDevice connectedDevice =
        BluetoothDevice(remoteId: widget.device.remoteId);
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        FloatingActionButton.extended(
            backgroundColor: CustomColors.mainColor_3,
            onPressed: onRefreshPressed,
            label: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            )),
        const IconButton(
          icon: SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
          ),
          onPressed: null,
        ),
      ],
    );
  }

  Widget buildMtuTile(BuildContext context) {
    return ListTile(
        title: const Text('MTU Size'),
        subtitle: Text('$_mtuSize bytes'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onRequestMtuPressed,
        ));
  }

  Widget buildConnectButton(BuildContext context) {
    return Row(children: [
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      TextButton(
          onPressed: _isConnecting
              ? onCancelPressed
              : (isConnected ? onDisconnectPressed : onConnectPressed),
          child: Text(
            _isConnecting ? "CANCEL" : (isConnected ? "DISCONNECT" : "CONNECT"),
            style: Theme.of(context)
                .primaryTextTheme
                .labelLarge
                ?.copyWith(color: Colors.black),
          ))
    ]);
  }

  Widget idleWidget() {
    final Size size = MediaQuery.of(context).size;

    Future<void> refreshData() async {
      setState(() {
        onRefreshPressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refreshData,
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                  data["Battery_voltage"] != null
                      ? "${data["Battery_voltage"]} V"
                      : "NA",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: size.height * 0.018),
                ),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_temperature',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_temperature"] != null
                        ? "${data["Battery_temperature"]} °C"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_health_status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_health_status"] != null
                        ? "${data["Battery_health_status"]} %"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Package_total_capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Package_total_capacity"] != null
                        ? "${data["Package_total_capacity"]} Ah"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_cycle_count',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_cycle_count"] != null
                        ? "${data["Battery_cycle_count"]}"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'BMS_fault',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["BMS_fault"] != null ? "${data["BMS_fault"]}" : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget chargingWidget() {
    final Size size = MediaQuery.of(context).size;

    Future<void> refreshData() async {
      setState(() {
        onRefreshPressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refreshData,
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_voltage"] != null
                        ? "${data["Battery_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_current',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_current"] != null
                        ? "${data["Battery_current"]} A"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_temperature',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_temperature"] != null
                        ? "${data["Battery_temperature"]} °C"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_health_status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_health_status"] != null
                        ? "${data["Battery_health_status"]} %"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Package_total_capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Package_total_capacity"] != null
                        ? "${data["Package_total_capacity"]} Ah"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Package_remaining_capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Package_remaining_capacity"] != null
                        ? "${data["Package_remaining_capacity"]} Ah"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_full_charge',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_full_charge"] != null
                        ? "${data["Battery_full_charge"]} mins"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Charging_Porfile_cv',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Charging_Porfile_cv"] != null
                        ? "${data["Charging_Porfile_cv"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Charging_Porfile_cc',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Charging_Porfile_cc"] != null
                        ? "${data["Charging_Porfile_cc"]} A"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell1_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell1_voltage"] != null
                        ? "${data["cell1_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell2_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell2_voltage"] != null
                        ? "${data["cell2_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell3_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell3_voltage"] != null
                        ? "${data["cell3_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell4_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell4_voltage"] != null
                        ? "${data["cell4_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell5_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell5_voltage"] != null
                        ? "${data["cell5_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell6_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell6_voltage"] != null
                        ? "${data["cell6_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell7_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell7_voltage"] != null
                        ? "${data["cell7_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell8_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell8_voltage"] != null
                        ? "${data["cell8_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell9_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell9_voltage"] != null
                        ? "${data["cell9_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell10_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell10_voltage"] != null
                        ? "${data["cell10_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell11_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell11_voltage"] != null
                        ? "${data["cell11_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell12_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell12_voltage"] != null
                        ? "${data["cell12_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell13_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell13_voltage"] != null
                        ? "${data["cell13_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell14_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell14_voltage"] != null
                        ? "${data["cell14_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell15_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell15_voltage"] != null
                        ? "${data["cell15_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'cell16_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["cell16_voltage"] != null
                        ? "${data["cell16_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'BMS_fault',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["BMS_fault"] != null ? "${data["BMS_fault"]}" : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dischargingWidget() {
    final Size size = MediaQuery.of(context).size;

    Future<void> refreshData() async {
      setState(() {
        onRefreshPressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refreshData,
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_voltage"] != null
                        ? "${data["Battery_voltage"]} V"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_current',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_current"] != null
                        ? "${data["Battery_current"]} A"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_temperature',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_temperature"] != null
                        ? "${data["Battery_temperature"]} °C"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_health_status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_health_status"] != null
                        ? "${data["Battery_health_status"]} %"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Package_total_capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Package_total_capacity"] != null
                        ? "${data["Package_total_capacity"]} Ah"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Package_remaining_capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Package_remaining_capacity"] != null
                        ? "${data["Package_remaining_capacity"]} Ah"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Battery_discharge',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["Battery_discharge"] != null
                        ? "${data["Battery_discharge"]} mins"
                        : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'BMS_fault',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    data["BMS_fault"] != null ? "${data["BMS_fault"]}" : "NA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final List<Widget> read_write_screens = [stateSelected(), writeScreen()];

    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyC,
      child: Scaffold(
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade500],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)),
            ),
            title: Text(widget.device.platformName),
            actions: [buildConnectButton(context)],
          ),
          body: Padding(
            padding: EdgeInsets.all(size.height * 0.01),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.01),
                stateSelectorShow(),
                Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade500],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                ),
                SizedBox(height: size.height * 0.01),
                SizedBox(
                  height: size.height * 0.01,
                ),
                read_write_screens[_selectedIndex]
              ],
            ),
          ),
          // floatingActionButton: buildDisplayData(context),
          // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          bottomNavigationBar: navShow()),
    );
  }
}
