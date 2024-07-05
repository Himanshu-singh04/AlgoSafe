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
  var _currentBmsState = 0; // 125: idle, 4: charging, 3:discharging

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

  final Map<String, TextEditingController> _ccontrollers = {
    "Battery_constant_current": TextEditingController(),
    "Battery_peak_current": TextEditingController(),
    "Battery_max_voltage": TextEditingController(),
    "Battery_min_voltage": TextEditingController(),
    "Battery_operating_temperature": TextEditingController(),
    "Battery_id": TextEditingController(),
    "Battery_DSG_C": TextEditingController(),
    "Battery_CHG_C": TextEditingController(),
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
    Widget abc = idleWidget();
    var statevalue = data["BMS_state"];
    if (statevalue is String) {
      _currentBmsState = int.tryParse(statevalue) ?? 0;
      print("${_currentBmsState} BMSstate");
    } else if (statevalue is int) {
      // ignore: cast_from_null_always_fails
      _currentBmsState = statevalue as int;
      print("${_currentBmsState} BMSstate");
    } else {
      _currentBmsState = 0;
      print("${_currentBmsState} BMSstate");
    }

    switch (_currentBmsState) {
      case 1:
      case 2:
      case 5:
        abc = idleWidget();
        break;

      case 4:
        abc = chargingWidget();
        break;

      case 3:
        abc = dischargingWidget();
        break;

      default:
        abc = idleWidget();
        break;
    }
    return abc;
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

  Map<String, List<String>> dropdownItems = {
    "Battery_configuration": ["2", "4", "6", "8", "10", "12", "14", "16"],
  };

  final Map<String, double> _sliderValues = {
    "Battery_constant_current": 0.0,
    "Battery_peak_current": 0.0,
    "Battery_max_voltage": 0.0,
    "Battery_min_voltage": 0.0,
    "Battery_operating_temperature": 0.0,
  };

  Map<String, List<double>> sliderMinMax = {
    "Battery_constant_current": [0.0, 180.0],
    "Battery_peak_current": [0.0, 180.0],
    "Battery_max_voltage": [0.0, 4350.0],
    "Battery_min_voltage": [0.0, 2500.0],
    "Battery_operating_temperature": [0.0, 80.0],
  };

  Map<String, int> sliderDivisions = {
    "Battery_constant_current": 90,
    "Battery_peak_current": 90,
    "Battery_max_voltage": 87,
    "Battery_min_voltage": 50,
    "Battery_operating_temperature": 80,
  };

  Map<String, bool> toggleValues = {
    "Battery_DSG_C": false,
    "Battery_CHG_C": false,
  };

  final _formKey = GlobalKey<FormState>();

  // Widget writeScreen() {
  //   final Size size = MediaQuery.of(context).size;
  //   return Expanded(
  //     child: Form(
  //       key: _formKey,
  //       child: ListView(
  //         children: [
  //           // buildDropdownForCharacteristic("Battery_configuration"),
  //           // SizedBox(height: size.height * 0.01),
  //           buildSliderForCharacteristic("Battery_constant_current"),
  //           SizedBox(height: size.height * 0.01),
  //           buildSliderForCharacteristic("Battery_peak_current"),
  //           SizedBox(height: size.height * 0.01),
  //           buildSliderForCharacteristic("Battery_max_voltage"),
  //           SizedBox(height: size.height * 0.01),
  //           buildSliderForCharacteristic("Battery_min_voltage"),
  //           SizedBox(height: size.height * 0.01),
  //           buildSliderForCharacteristic("Battery_operating_temperature"),
  //           SizedBox(height: size.height * 0.01),
  //           buildTextFieldForCharacteristic("Battery_id", isRequired: true),
  //           // SizedBox(height: size.height * 0.01),
  //           // buildTextFieldForCharacteristic("BMS_id", isRequired: true),
  //           SizedBox(height: size.height * 0.01),
  //           buildToggleForCharacteristic("Battery_DSG_C"),
  //           SizedBox(height: size.height * 0.01),
  //           buildToggleForCharacteristic("Battery_CHG_C"),
  //           SizedBox(height: size.height * 0.02),
  //           ElevatedButton(
  //             onPressed: () {
  //               if (_formKey.currentState!.validate()) {
  //                 onSendAllPressed();
  //               }
  //             },
  //             child: Text('Send'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget writeScreen() {
    final Size size = MediaQuery.of(context).size;
    return Expanded(
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            ExpansionTile(
              title: Text('Compulsory Fields'),
              initiallyExpanded: true,
              children: [
                // buildDropdownForCharacteristic("Battery_configuration"),
                // SizedBox(height: size.height * 0.01),
                buildTextFieldForCharacteristic("Battery_id", isRequired: true),
                SizedBox(height: size.height * 0.01),
                // buildTextFieldForCharacteristic("BMS_id", isRequired: true),
                // SizedBox(height: size.height * 0.01),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            ExpansionTile(
              title: Text('Default Values'),
              initiallyExpanded: true,
              children: [
                buildSliderForCharacteristic("Battery_constant_current"),
                SizedBox(height: size.height * 0.01),
                buildSliderForCharacteristic("Battery_peak_current"),
                SizedBox(height: size.height * 0.01),
                buildSliderForCharacteristic("Battery_max_voltage"),
                SizedBox(height: size.height * 0.01),
                buildSliderForCharacteristic("Battery_min_voltage"),
                SizedBox(height: size.height * 0.01),
                buildSliderForCharacteristic("Battery_operating_temperature"),
                SizedBox(height: size.height * 0.01),
                buildToggleForCharacteristic("Battery_DSG_C"),
                SizedBox(height: size.height * 0.01),
                buildToggleForCharacteristic("Battery_CHG_C"),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.mainColor_1),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  onSendAllPressed();
                }
              },
              child: Text(
                "Save Configuration",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextFieldForCharacteristic(String key,
      {bool isRequired = false}) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.height * 0.01),
        color: CustomColors.mainColor_3,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                style: TextStyle(color: Colors.white),
                controller: _controllers[key],
                decoration: InputDecoration(
                  labelText: key.replaceAll('_', ' '),
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                validator: isRequired
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter $key';
                        }
                        return null;
                      }
                    : null,
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
        color: CustomColors.mainColor_3,
      ),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select $key';
                  }
                  return null;
                },
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

  Widget buildSliderForCharacteristic(String key) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.height * 0.01),
        color: CustomColors.mainColor_3,
      ),
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
                      Spacer(),
                      Container(
                        width: size.width * 0.65,
                        child: Slider(
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
                      ),
                      Spacer(),
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

  Widget buildToggleForCharacteristic(String key) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.height * 0.01),
        color: CustomColors.mainColor_3,
      ),
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
                  Spacer(),
                  Switch(
                    activeColor: Colors.grey,
                    value: toggleValues[key] ?? false,
                    onChanged: (bool newValue) {
                      setState(() {
                        toggleValues[key] = newValue;
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

  Map<String, String> lastSentValues = {};

  Future<void> onSendAllPressed() async {
    bool allSuccess = true;
    String summaryMessage = '';

    for (String characteristicName in uuid_algoBMS_write.keys) {
      String? characteristicUuid = uuid_algoBMS_write[characteristicName];
      String value = _controllers[characteristicName]?.text ?? '';

      if (value.isEmpty || characteristicUuid == null) {
        summaryMessage +=
            '$characteristicName Write: No value provided or invalid UUID\n';
        allSuccess = false;
        continue;
      }

      // Check if the value has changed since the last send
      if (lastSentValues[characteristicName] == value) {
        summaryMessage +=
            '$characteristicName Write: Value unchanged, not sending\n';
        continue;
      }

      BluetoothCharacteristic? targetCharacteristic;

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
          if (targetCharacteristic.properties.writeWithoutResponse) {
            await targetCharacteristic.write(value.codeUnits,
                withoutResponse: true);
            summaryMessage += '$characteristicName Write: Success\n';
          } else if (targetCharacteristic.properties.write) {
            await targetCharacteristic.write(value.codeUnits,
                withoutResponse: false);
            summaryMessage += '$characteristicName Write: Success\n';
          } else {
            summaryMessage +=
                '$characteristicName Write: Characteristic not writable\n';
            allSuccess = false;
          }
          // Update the last sent value after a successful send
          lastSentValues[characteristicName] = value;
        } catch (e) {
          summaryMessage += '$characteristicName Write: Error - $e\n';
          allSuccess = false;
        }
      } else {
        summaryMessage +=
            '$characteristicName Write: Characteristic not found\n';
        allSuccess = false;
      }
    }

    Snackbar.show(ABC.c, summaryMessage, success: allSuccess);
  }

  // Map<String, String> lastSentValues = {};

  // Future<void> onSendAllPressed() async {
  //   bool allSuccess = true;
  //   String summaryMessage = '';
  //   List<String> compulsoryItems = [
  //     // "Battery_id",
  //     // "Battery_DSG_C",
  //     // "Battery_CHG_C"
  //   ];

  //   // Check if all compulsory items are set
  //   for (String item in compulsoryItems) {
  //     String value = _controllers[item]?.text ?? '';
  //     if (value.isEmpty) {
  //       summaryMessage += '$item Write: Compulsory item not set\n';
  //       allSuccess = false;
  //     }
  //   }

  //   // If any compulsory item is not set, show a message and return
  //   if (!allSuccess) {
  //     Snackbar.show(ABC.c, summaryMessage, success: false);
  //     return;
  //   }

  //   // Proceed with the write operations
  //   for (String characteristicName in uuid_algoBMS_write.keys) {
  //     String? characteristicUuid = uuid_algoBMS_write[characteristicName];
  //     String value = _controllers[characteristicName]?.text ?? '';

  //     if (value.isEmpty || characteristicUuid == null) {
  //       summaryMessage +=
  //           '$characteristicName Write: No value provided or invalid UUID\n';
  //       allSuccess = false;
  //       continue;
  //     }

  //     // Check if the value has changed since the last send
  //     if (lastSentValues[characteristicName] == value) {
  //       summaryMessage +=
  //           '$characteristicName Write: Value unchanged, not sending\n';
  //       continue;
  //     }

  //     BluetoothCharacteristic? targetCharacteristic;

  //     for (var service in _services) {
  //       for (var characteristic in service.characteristics) {
  //         if (characteristic.uuid.toString() == characteristicUuid) {
  //           targetCharacteristic = characteristic;
  //           break;
  //         }
  //       }
  //       if (targetCharacteristic != null) break;
  //     }

  //     if (targetCharacteristic != null) {
  //       try {
  //         if (targetCharacteristic.properties.writeWithoutResponse) {
  //           await targetCharacteristic.write(value.codeUnits,
  //               withoutResponse: true);
  //           summaryMessage += '$characteristicName Write: Success\n';
  //         } else if (targetCharacteristic.properties.write) {
  //           await targetCharacteristic.write(value.codeUnits,
  //               withoutResponse: false);
  //           summaryMessage += '$characteristicName Write: Success\n';
  //         } else {
  //           summaryMessage +=
  //               '$characteristicName Write: Characteristic not writable\n';
  //           allSuccess = false;
  //         }
  //         // Update the last sent value after a successful send
  //         lastSentValues[characteristicName] = value;
  //       } catch (e) {
  //         summaryMessage += '$characteristicName Write: Error - $e\n';
  //         allSuccess = false;
  //       }
  //     } else {
  //       summaryMessage +=
  //           '$characteristicName Write: Characteristic not found\n';
  //       allSuccess = false;
  //     }
  //   }

  //   Snackbar.show(ABC.c, summaryMessage, success: allSuccess);
  // }

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
      case 1:
      case 2:
      case 5: // Idle Mode
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

      case 4: // Charging Mode
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

      case 3: // Discharging Mode
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
      case 1:
      case 2:
      case 5:
        return bottomNavigationBar();

      case 4:
        return SizedBox.shrink();

      case 3:
        return SizedBox.shrink();

      default:
        return bottomNavigationBar();
    }
  }

  Widget bottomNavigationBar() {
    final Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.05,
      decoration: BoxDecoration(
        color: CustomColors.mainColor_1,
        borderRadius: BorderRadius.circular(20)
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: Colors.amber,
            backgroundColor: Colors.deepPurple,
            labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return TextStyle(color: Colors.grey); // Color for selected label
                }
                return TextStyle(color: Colors.white); // Color for unselected labels
              },
            ),
          )
        ),
        child: NavigationBar(
          indicatorColor: CustomColors.mainColor_3,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          height: size.height * 0.1,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: <NavigationDestination>[
            NavigationDestination(
                icon: Icon(Icons.my_library_books,color: Colors.white,), label: "Data Monitoring"),
            NavigationDestination(
                icon: Icon(Icons.edit,color: Colors.white), label: "Data Configuration")
          ],
        ),
      ),
    );
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
                ?.copyWith(color: Colors.white),
          ))
    ]);
  }

  Widget idleWidget() {
    final Size size = MediaQuery.of(context).size;
    double batteryVoltage = data["Battery_voltage"] != null
        ? double.parse(data["Battery_voltage"]!)
        : 0.0;

    double batteryTemperature = data["Battery_temperature"] != null
        ? double.parse(data["Battery_temperature"]!)
        : 0.0;

    double batteryHealthStatus = data["Battery_health_status"] != null
        ? double.parse(data["Battery_health_status"]!)
        : 0.0;

    double packageTotalCapacity = data["Package_total_capacity"] != null
        ? double.parse(data["Package_total_capacity"]!)
        : 0.0;

    double batteryCycleCount = data["Battery_cycle_count"] != null
        ? double.parse(data["Battery_cycle_count"]!)
        : 0.0;

    double bmsFault =
        data["BMS_fault"] != null ? double.parse(data["BMS_fault"]!) : 0.0;

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
                  'Battery Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryVoltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Battery Temperature',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryTemperature * 0.01).toStringAsFixed(2) + ' °C',
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
                  'Battery Health Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryHealthStatus * 0.001).toStringAsFixed(3) + ' %',
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
                  'Package Total Capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (packageTotalCapacity * 1).toStringAsFixed(0) + ' mAh',
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
                  'Battery Cycle Count',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((batteryCycleCount * 1).toStringAsFixed(0) + ' ',
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
                  'BMS Fault',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((bmsFault * 1).toStringAsFixed(0) + ' ',
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

    double batteryVoltage = data["Battery_voltage"] != null
        ? double.parse(data["Battery_voltage"]!)
        : 0.0;

    double batteryCurrent = data["Battery_current"] != null
        ? double.parse(data["Battery_current"]!)
        : 0.0;

    double batteryTemperature = data["Battery_temperature"] != null
        ? double.parse(data["Battery_temperature"]!)
        : 0.0;

    double batteryHealthStatus = data["Battery_health_status"] != null
        ? double.parse(data["Battery_health_status"]!)
        : 0.0;

    double packageTotalCapacity = data["Package_total_capacity"] != null
        ? double.parse(data["Package_total_capacity"]!)
        : 0.0;

    double packageRemainingCapacity = data["Package_remaining_capacity"] != null
        ? double.parse(data["Package_remaining_capacity"]!)
        : 0.0;

    double batteryFullCharge = data["Battery_full_charge"] != null
        ? double.parse(data["Battery_full_charge"]!)
        : 0.0;

    double chargingPorfileCV = data["Charging_Porfile_cv"] != null
        ? double.parse(data["Charging_Porfile_cv"]!)
        : 0.0;

    double chargingPorfileCC = data["Charging_Porfile_cc"] != null
        ? double.parse(data["Charging_Porfile_cc"]!)
        : 0.0;

    double cell1Voltage = data["cell1_voltage"] != null
        ? double.parse(data["cell1_voltage"]!)
        : 0.0;

    double cell2Voltage = data["cell2_voltage"] != null
        ? double.parse(data["cell2_voltage"]!)
        : 0.0;

    double cell3Voltage = data["cell3_voltage"] != null
        ? double.parse(data["cell3_voltage"]!)
        : 0.0;

    double cell4Voltage = data["cell4_voltage"] != null
        ? double.parse(data["cell4_voltage"]!)
        : 0.0;

    double cell5Voltage = data["cell5_voltage"] != null
        ? double.parse(data["cell5_voltage"]!)
        : 0.0;

    double cell6Voltage = data["cell6_voltage"] != null
        ? double.parse(data["cell6_voltage"]!)
        : 0.0;

    double cell7Voltage = data["cell7_voltage"] != null
        ? double.parse(data["cell7_voltage"]!)
        : 0.0;

    double cell8Voltage = data["cell8_voltage"] != null
        ? double.parse(data["cell8_voltage"]!)
        : 0.0;

    double cell9Voltage = data["cell9_voltage"] != null
        ? double.parse(data["cell9_voltage"]!)
        : 0.0;

    double cell10Voltage = data["cell10_voltage"] != null
        ? double.parse(data["cell10_voltage"]!)
        : 0.0;

    double cell11Voltage = data["cell11_voltage"] != null
        ? double.parse(data["cell11_voltage"]!)
        : 0.0;

    double cell12Voltage = data["cell12_voltage"] != null
        ? double.parse(data["cell12_voltage"]!)
        : 0.0;

    double cell13Voltage = data["cell13_voltage"] != null
        ? double.parse(data["cell13_voltage"]!)
        : 0.0;

    double cell14Voltage = data["cell14_voltage"] != null
        ? double.parse(data["cell14_voltage"]!)
        : 0.0;

    double cell15Voltage = data["cell15_voltage"] != null
        ? double.parse(data["cell15_voltage"]!)
        : 0.0;

    double cell16Voltage = data["cell16_voltage"] != null
        ? double.parse(data["cell16_voltage"]!)
        : 0.0;

    double bmsFault =
        data["BMS_fault"] != null ? double.parse(data["BMS_fault"]!) : 0.0;

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
                  'Battery Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryVoltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Battery Current',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryCurrent * 0.01).toStringAsFixed(2) + ' A',
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
                  'Battery Temperature',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryTemperature * 0.01).toStringAsFixed(2) + ' °C',
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
                  'Battery Health Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryHealthStatus * 0.001).toStringAsFixed(2) + ' %',
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
                  'Package Total Capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (packageTotalCapacity * 1).toStringAsFixed(0) + ' mAh',
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
                  'Package Remaining Capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (packageRemainingCapacity * 1).toStringAsFixed(0) + ' mAh',
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
                  'Battery Full Charge',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryFullCharge * 0.01).toStringAsFixed(2) + ' mins',
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
                  'Charging Porfile CV',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (chargingPorfileCV * 0.001).toStringAsFixed(3) + ' V',
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
                  'Charging Porfile CC',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (chargingPorfileCC * 0.001).toStringAsFixed(3) + ' A',
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
                  'Cell1 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell1Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell2 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell2Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell3 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell3Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell4 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell4Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell5 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell5Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell6 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell6Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell7 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell7Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell8 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell8Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell9 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((cell9Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell10 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (cell10Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell11 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (cell11Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell12 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (cell12Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell13 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (cell13Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell14 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (cell14Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell15 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (cell15Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'Cell16 Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (cell16Voltage * 0.001).toStringAsFixed(3) + ' V',
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
                  'BMS Fault',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((bmsFault * 1).toStringAsFixed(0) + ' ',
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

    double batteryVoltage = data["Battery_voltage"] != null
        ? double.parse(data["Battery_voltage"]!)
        : 0.0;

    double batteryCurrent = data["Battery_current"] != null
        ? double.parse(data["Battery_current"]!)
        : 0.0;

    double batteryTemperature = data["Battery_temperature"] != null
        ? double.parse(data["Battery_temperature"]!)
        : 0.0;

    double batteryHealthStatus = data["Battery_health_status"] != null
        ? double.parse(data["Battery_health_status"]!)
        : 0.0;

    double packageTotalCapacity = data["Package_total_capacity"] != null
        ? double.parse(data["Package_total_capacity"]!)
        : 0.0;

    double packageRemainingCapacity = data["Package_remaining_capacity"] != null
        ? double.parse(data["Package_remaining_capacity"]!)
        : 0.0;

    double batteryDischarge = data["Battery_discharge"] != null
        ? double.parse(data["Battery_discharge"]!)
        : 0.0;

    double bmsFault =
        data["BMS_fault"] != null ? double.parse(data["BMS_fault"]!) : 0.0;

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
                  'Battery Voltage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryVoltage * 0.001).toStringAsFixed(2) + ' V',
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
                  'Battery Current',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryCurrent * 0.01).toStringAsFixed(2) + ' A',
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
                  'Battery Temperature',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryTemperature * 0.01).toStringAsFixed(2) + ' °C',
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
                  'Battery Health Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryHealthStatus * 0.001).toStringAsFixed(3) + ' %',
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
                  'Package Total Capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (packageTotalCapacity * 1).toStringAsFixed(0) + ' mAh',
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
                  'Package Remaining Capacity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (packageRemainingCapacity * 1).toStringAsFixed(0) + ' mAh',
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
                  'Battery Discharge',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(
                    (batteryDischarge * 0.01).toStringAsFixed(2) + ' mins',
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
                  'BMS Fault',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text((bmsFault * 1).toStringAsFixed(0) + ' ',
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
            iconTheme: IconThemeData(color: Colors.white),
            backgroundColor: Colors.white,
            toolbarHeight: size.height * 0.05,
            flexibleSpace: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
              child: Container(
                color: CustomColors.mainColor_1,
              ),
            ),
            title: Text(widget.device.platformName,style: TextStyle(color: Colors.white),),
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
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: navShow(),
          )),
    );
  }
}
