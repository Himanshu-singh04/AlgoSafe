import 'dart:async';
import 'dart:typed_data';
import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/extra.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DisplayDataScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DisplayDataScreen({super.key, required this.device});

  @override
  State<DisplayDataScreen> createState() => _DisplayDataScreenState();
}

class _DisplayDataScreenState extends State<DisplayDataScreen> {
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;

  Map<String, String> uuids = {
    "BMS_state": "606d63cb-6f2c-42d0-9a1d-c3c20749c487",
    "Battery_configuration": "53072650-6e04-40f5-89a0-5914d2324b3b",
    "Battery_voltage": "6c1e0a36-f854-49f2-a78f-3db43f6424b1",
    "Battery_current": "ffe56b2d-0607-428f-ba10-7a76268c4420",
    "Battery_temperature": "ee24bdeb-7408-4cec-8186-27e01bf301d7",
    "Battery_cycle_count": "0492a1ac-d680-4e46-a28d-0422753dd0b3",
    "Battery_health_status": "96ff5f4c-4830-4ec1-95d8-8f92a4bba717",
    "BMS_fault": "28fcf388-dbe0-4453-a1aa-7f41116e0e58",
    "Package_total_capacity": "0494e147-8541-4917-be37-09540a7f3161",
    "Package_remaining_capacity": "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e",
    "cell1_voltage": "59878c02-5bfc-42c1-9c91-861b3f262ee0",
    "cell2_voltage": "9bc4eb20-faef-48a3-a2d3-04a4977225d6",
    "cell3_voltage": "dd5d4670-160e-4304-8a09-bbadfc7c1dec",
    "cell4_voltage": "a3c48189-4ee2-40e1-86ee-7291fb61939d",
    "cell5_voltage": "a1d5d1fa-691b-4f82-8c6e-98945243d711",
    "cell6_voltage": "7d7f5064-9f05-4723-8c9a-49ca699a7535",
    "cell7_voltage": "df8de357-450d-4373-bf3b-d3fcbb61d4a7",
    "cell8_voltage": "6d3efe3d-e699-49ee-a01a-df60700305be",
    "cell9_voltage": "3b9c753a-53cb-4a55-aed6-2f6609250341",
    "cell10_voltage": "35496015-80bd-43b3-91ee-50aadb953ed8",
    "cell11_voltage": "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd",
    "cell12_voltage": "9452d6c5-3467-41f1-96fe-91df261efbcf",
    "cell13_voltage": "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c",
    "cell14_voltage": "a13f06e2-a6a8-4ecf-a130-441ab94f337d",
    "cell15_voltage": "1d6a23ef-523d-446c-93c0-53eebad0eca9",
    "cell16_voltage": "4c776ff8-7448-4ba0-b238-1010b4a62297",
    "Battery_discharge": "24688ee9-9c1d-45bf-ba47-2b36cb92ace5",
    "Battery_full_charge": "79bda1ab-8b37-421a-83b7-01c1980bdec1",
    "Charging_Porf_cc": "16423408-9605-4312-a369-45bcacd6a880",
    "Charging_Porf_cv": "c628e8ca-6c4e-4cda-88b1-6ca0f9320855"
  };

  Map<String, String> data = {};
  final TextEditingController _writeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.device.connectionState.listen((state) async {
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

    _isDisconnectingSubscription = widget.device.isDisconnecting.listen((value) {
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
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
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
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e), success: false);
    }
  }

  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
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
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e), success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  int parseUint16(List<int> value) {
    final ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));
    return byteData.getUint16(0, Endian.little);
  }

  Future subscribeToCharacteristic(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    characteristic.value.listen((value) {
      String characteristicKey = uuids.keys
          .firstWhere((key) => uuids[key] == characteristic.uuid.toString());

      if (value.isNotEmpty) {
        String parsedValue = parseUint16(value).toString();
        setState(() {
          data[characteristicKey] = parsedValue;
        });
      }
    });
  }

  Future writeCharacteristic(BluetoothCharacteristic characteristic, String value) async {
    List<int> bytes = value.codeUnits;
    await characteristic.write(bytes, withoutResponse: true);
  }

  Future onWritePressed() async {
    if (_writeController.text.isEmpty) {
      Snackbar.show(ABC.c, "Write Value: Empty", success: false);
      return;
    }

    for (var service in _services) {
      for (var characteristic in service.characteristics) {
        if (uuids.containsValue(characteristic.uuid.toString()) &&
            (characteristic.properties.write || characteristic.properties.writeWithoutResponse)) {
          await writeCharacteristic(characteristic, _writeController.text);
          Snackbar.show(ABC.c, "Write: Success", success: true);
          return;
        }
      }
    }

    Snackbar.show(ABC.c, "Write: Characteristic not found or not writable", success: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.localName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: onConnectPressed,
              child: const Text("Connect"),
            ),
            ElevatedButton(
              onPressed: onDisconnectPressed,
              child: const Text("Disconnect"),
            ),
            ElevatedButton(
              onPressed: onCancelPressed,
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: onDiscoverServicesPressed,
              child: const Text("Discover Services"),
            ),
            const SizedBox(height: 20),
            _isDiscoveringServices
                ? const CircularProgressIndicator()
                : const SizedBox.shrink(),
            TextField(
              controller: _writeController,
              decoration: const InputDecoration(
                labelText: "Write Value",
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: onWritePressed,
              child: const Text("Write"),
            ),
            Expanded(
              child: ListView(
                children: data.entries
                    .map((entry) => ListTile(
                          title: Text(entry.key),
                          subtitle: Text(entry.value),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//import 'dart:async';
//import 'dart:typed_data';
//import 'package:algo_safe/utils/colors.dart';
//import 'package:algo_safe/utils/extra.dart';
//import 'package:algo_safe/utils/snack_bar.dart';

//import 'package:flutter/material.dart';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart';

//class display_data_screen extends StatefulWidget {
// final BluetoothDevice device;
//  const display_data_screen({super.key, required this.device});

//  @override
//  State<display_data_screen> createState() => _display_data_screenState();
//}

//class _display_data_screenState extends State<display_data_screen> {
//  int? _rssi;
//  int? _mtuSize;
//  BluetoothConnectionState _connectionState =
//      BluetoothConnectionState.disconnected;
//  List<BluetoothService> _services = [];
//  bool _isDiscoveringServices = false;
//  bool _isConnecting = false;
//  bool _isDisconnecting = false;

//  late StreamSubscription<BluetoothConnectionState>
//      _connectionStateSubscription;
//  late StreamSubscription<bool> _isConnectingSubscription;
//  late StreamSubscription<bool> _isDisconnectingSubscription;
//  late StreamSubscription<int> _mtuSubscription;

//  Map<String, String> uuids = {
//    "BMS_state": "606d63cb-6f2c-42d0-9a1d-c3c20749c487",
//    "Battery_configuration": "53072650-6e04-40f5-89a0-5914d2324b3b",
//    "Battery_voltage": "6c1e0a36-f854-49f2-a78f-3db43f6424b1",
//    "Battery_current": "ffe56b2d-0607-428f-ba10-7a76268c4420",
//    "Battery_temperature": "ee24bdeb-7408-4cec-8186-27e01bf301d7",
//    "Battery_cycle_count": "0492a1ac-d680-4e46-a28d-0422753dd0b3",
//    "Battery_health_status": "96ff5f4c-4830-4ec1-95d8-8f92a4bba717",
//    "BMS_fault": "28fcf388-dbe0-4453-a1aa-7f41116e0e58",
//    "Package_total_capacity": "0494e147-8541-4917-be37-09540a7f3161",
//    "Package_remaining_capacity": "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e",
//    "cell1_voltage": "59878c02-5bfc-42c1-9c91-861b3f262ee0",
//    "cell2_voltage": "9bc4eb20-faef-48a3-a2d3-04a4977225d6",
//    "cell3_voltage": "dd5d4670-160e-4304-8a09-bbadfc7c1dec",
//    "cell4_voltage": "a3c48189-4ee2-40e1-86ee-7291fb61939d",
//    "cell5_voltage": "a1d5d1fa-691b-4f82-8c6e-98945243d711",
//    "cell6_voltage": "7d7f5064-9f05-4723-8c9a-49ca699a7535",
//    "cell7_voltage": "df8de357-450d-4373-bf3b-d3fcbb61d4a7",
//    "cell8_voltage": "6d3efe3d-e699-49ee-a01a-df60700305be",
//    "cell9_voltage": "3b9c753a-53cb-4a55-aed6-2f6609250341",
//    "cell10_voltage": "35496015-80bd-43b3-91ee-50aadb953ed8",
//    "cell11_voltage": "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd",
//    "cell12_voltage": "9452d6c5-3467-41f1-96fe-91df261efbcf",
//    "cell13_voltage": "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c",
//    "cell14_voltage": "a13f06e2-a6a8-4ecf-a130-441ab94f337d",
//    "cell15_voltage": "1d6a23ef-523d-446c-93c0-53eebad0eca9",
//    "cell16_voltage": "4c776ff8-7448-4ba0-b238-1010b4a62297",
//    "Battery_discharge": "24688ee9-9c1d-45bf-ba47-2b36cb92ace5",
//    "Battery_full_charge": "79bda1ab-8b37-421a-83b7-01c1980bdec1",
//    "Charging_Porf_cc": "16423408-9605-4312-a369-45bcacd6a880",
//    "Charging_Porf_cv": "c628e8ca-6c4e-4cda-88b1-6ca0f9320855"
//  };
//
//  Map<String, String> data = {};

///  @override
//  void initState() {
//    super.initState();
//
//    _connectionStateSubscription =
//        widget.device.connectionState.listen((state) async {
//      _connectionState = state;
//      if (state == BluetoothConnectionState.connected) {
//        _services = []; // must rediscover services
//      }
//      if (state == BluetoothConnectionState.connected && _rssi == null) {
//        _rssi = await widget.device.readRssi();
//      }
//      if (mounted) {
//        setState(() {});
//      }
//    });
//
//    _mtuSubscription = widget.device.mtu.listen((value) {
//      _mtuSize = value;
//      if (mounted) {
//        setState(() {});
//      }
//    });
//
//    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
//     _isConnecting = value;
//      if (mounted) {
//        setState(() {});
//      }
//    });
//
//    _isDisconnectingSubscription =
//        widget.device.isDisconnecting.listen((value) {
//      _isDisconnecting = value;
//      if (mounted) {
//        setState(() {});
//      }
//    });
//  }
//
//  @override
//  void dispose() {
//    _connectionStateSubscription.cancel();
//    _mtuSubscription.cancel();
//   _isConnectingSubscription.cancel();
//    _isDisconnectingSubscription.cancel();
//    super.dispose();
//  }
//
//  bool get isConnected {
//    return _connectionState == BluetoothConnectionState.connected;
//  }
//
// Future onConnectPressed() async {
  //   try {
  //     await widget.device.connectAndUpdateStream();
  //     Snackbar.show(ABC.c, "Connect: Success", success: true);
  //   } catch (e) {
  //     if (e is FlutterBluePlusException &&
  //         e.code == FbpErrorCode.connectionCanceled.index) {
  //       // ignore connections canceled by the user
  //     } else {
  //       Snackbar.show(ABC.c, prettyException("Connect Error:", e),
  //           success: false);
  //     }
  //   }
  // }

  // Future onCancelPressed() async {
  //   try {
  //     await widget.device.disconnectAndUpdateStream(queue: false);
  //     Snackbar.show(ABC.c, "Cancel: Success", success: true);
  //   } catch (e) {
  //     Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
  //   }
  // }

  // Future onDisconnectPressed() async {
  //   try {
  //     await widget.device.disconnectAndUpdateStream();
  //     Snackbar.show(ABC.c, "Disconnect: Success", success: true);
  //   } catch (e) {
  //     Snackbar.show(ABC.c, prettyException("Disconnect Error:", e),
  //         success: false);
  //   }
  // }

  // Future onDiscoverServicesPressed() async {
  //   if (mounted) {
  //     setState(() {
  //       _isDiscoveringServices = true;
  //     });
  //   }
  //   try {
  //     _services = await widget.device.discoverServices();
  //     for (var service in _services){
  //       for (var characteristic in service.characteristics){
  //         switch (characteristic.uuid.toString()){
  //           case "606d63cb-6f2c-42d0-9a1d-c3c20749c487" : subscribeToBMSState(characteristic);
  //           break;

  //           case "53072650-6e04-40f5-89a0-5914d2324b3b" : subscribeToBatteryConfiguration(characteristic);
  //           break;

  //           case "6c1e0a36-f854-49f2-a78f-3db43f6424b1" : subscribeToBatteryVoltage(characteristic);
  //           break;

  //           case "ffe56b2d-0607-428f-ba10-7a76268c4420" : subscribeToBatteryCurrent(characteristic);
  //           break;

  //           case "ee24bdeb-7408-4cec-8186-27e01bf301d7" : subscribeToBatteryTemperature(characteristic);
  //           break;

  //           case "0492a1ac-d680-4e46-a28d-0422753dd0b3" : subscribeToBatteryCycleCount(characteristic);
  //           break;

  //           case "96ff5f4c-4830-4ec1-95d8-8f92a4bba717" : subscribeToBatteryHealthStatus(characteristic);
  //           break;

  //           case "28fcf388-dbe0-4453-a1aa-7f41116e0e58" : subscribeToBMSFault(characteristic);
  //           break;

  //           case "0494e147-8541-4917-be37-09540a7f3161" : subscribeToPackageTotalCapacity(characteristic);
  //           break;

  //           case "2e2cb9b4-02d9-4ac3-a97e-52f3c6b0c51e" : subscribeToPackageRemainingCapacity(characteristic);
  //           break;

  //           case "59878c02-5bfc-42c1-9c91-861b3f262ee0" : subscribeToCell1Voltage(characteristic);
  //           break;

  //           case "9bc4eb20-faef-48a3-a2d3-04a4977225d6" : subscribeToCell2Voltage(characteristic);
  //           break;

  //           case "dd5d4670-160e-4304-8a09-bbadfc7c1dec" : subscribeToCell3Voltage(characteristic);
  //           break;

  //           case "a3c48189-4ee2-40e1-86ee-7291fb61939d" : subscribeToCell4Voltage(characteristic);
  //           break;

  //           case "a1d5d1fa-691b-4f82-8c6e-98945243d711" : subscribeToCell5Voltage(characteristic);
  //           break;

  //           case "7d7f5064-9f05-4723-8c9a-49ca699a7535" : subscribeToCell6Voltage(characteristic);
  //           break;

  //           case "df8de357-450d-4373-bf3b-d3fcbb61d4a7" : subscribeToCell7Voltage(characteristic);
  //           break;

  //           case "6d3efe3d-e699-49ee-a01a-df60700305be" : subscribeToCell8Voltage(characteristic);
  //           break;

  //           case "3b9c753a-53cb-4a55-aed6-2f6609250341" : subscribeToCell9Voltage(characteristic);
  //           break;

  //           case "35496015-80bd-43b3-91ee-50aadb953ed8" : subscribeToCell10Voltage(characteristic);
  //           break;

  //           case "a69b3c58-36ef-4b22-ad0b-dbb0af5dbacd" : subscribeToCell11Voltage(characteristic);
  //           break;

  //           case "9452d6c5-3467-41f1-96fe-91df261efbcf" : subscribeToCell12Voltage(characteristic);
  //           break;

  //           case "0bc76b72-e9a7-4be7-bf53-0d0c897d8a5c" : subscribeToCell13Voltage(characteristic);
  //           break;

  //           case "a13f06e2-a6a8-4ecf-a130-441ab94f337d" : subscribeToCell14Voltage(characteristic);
  //           break;

  //           case "1d6a23ef-523d-446c-93c0-53eebad0eca9" : subscribeToCell15Voltage(characteristic);
  //           break;

  //           case "4c776ff8-7448-4ba0-b238-1010b4a62297" : subscribeToCell16Voltage(characteristic);
  //           break;

  //           case "24688ee9-9c1d-45bf-ba47-2b36cb92ace5" : subscribeToBatteryDischarge(characteristic);
  //           break;

  //           case "79bda1ab-8b37-421a-83b7-01c1980bdec1" : subscribeToBatteryFullCharge(characteristic);
  //           break;

  //           case "16423408-9605-4312-a369-45bcacd6a880" : subscribeToChargingProfileCC(characteristic);
  //           break;

  //           case "c628e8ca-6c4e-4cda-88b1-6ca0f9320855" : subscribeToChargingProfileCV(characteristic);
  //           break;
  //         }
  //       }
  //     }
  //     Snackbar.show(ABC.c, "Discover Services: Success", success: true);
  //   } catch (e) {
  //     Snackbar.show(ABC.c, prettyException("Discover Services Error:", e),
  //         success: false);
  //   }
  //   if (mounted) {
  //     setState(() {
  //       _isDiscoveringServices = false;
  //     });
  //   }
  // }

  // int parseUint16(List<int> value){
  //   var byteData = ByteData.sublistView(Uint8List.fromList(value));
  //   return byteData.getInt16(0, Endian.little);
  // }

  // void subscribeToCharacteristic(BluetoothCharacteristic characteristic, String name){
  //   characteristic.setNotifyValue(true);
  //   characteristic.value.listen((value){
  //     setState(() {
  //      data[name] = parseUint16(value) as String; 
  //     });
  //   });
  // }

  // void subscribeToBatteryVoltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Battery_voltage');
  // }

  //   void subscribeToBMSState(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'BMS_state');
  // }

  //   void subscribeToBatteryConfiguration(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Battery_configuration');
  // }

  //   void subscribeToBatteryCurrent(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Battery_current');
  // }

  //   void subscribeToBatteryTemperature(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Battery_temperature');
  // }

  //   void subscribeToBatteryCycleCount(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Battery_cycle_count');
  // }

  //   void subscribeToBatteryHealthStatus(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Battery_health_status');
  // }

  //   void subscribeToBMSFault(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'BMS_fault');
  // }

  //   void subscribeToPackageTotalCapacity(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Package_total_capacity');
  // }

  //   void subscribeToPackageRemainingCapacity(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Package_remaining_capacity');
  // }

  //     void subscribeToCell1Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell1_voltage');
  // }

  //     void subscribeToCell2Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell2_voltage');
  // }

  //     void subscribeToCell3Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell3_voltage');
  // }

  //     void subscribeToCell4Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell4_voltage');
  // }

  //     void subscribeToCell5Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell5_voltage');
  // }

  //   void subscribeToCell6Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell6_voltage');
  // }

  //     void subscribeToCell7Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell7_voltage');
  // }

  //     void subscribeToCell8Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell8_voltage');
  // }

  //     void subscribeToCell9Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell9_voltage');
  // }

  //     void subscribeToCell10Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell10_voltage');
  // }

  //     void subscribeToCell11Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell11_voltage');
  // }

  //     void subscribeToCell12Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell12_voltage');
  // }

  //     void subscribeToCell13Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell13_voltage');
  // }

  //     void subscribeToCell14Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell14_voltage');
  // }

  //     void subscribeToCell15Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell15_voltage');
  // }

  //     void subscribeToCell16Voltage(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'cell16_voltage');
  // }

  //     void subscribeToBatteryDischarge(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Battery_discharge');
  // }

  //     void subscribeToBatteryFullCharge(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Battery_full_charge');
  // }

  //     void subscribeToChargingProfileCC(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Charging_Porf_cc');
  // }

  //     void subscribeToChargingProfileCV(BluetoothCharacteristic characteristic) {
  //   subscribeToCharacteristic(characteristic, 'Charging_Porf_cv');
  // }

  // Widget buildSpinner(BuildContext context) {
  //   return const Padding(
  //     padding: EdgeInsets.all(14.0),
  //     child: AspectRatio(
  //       aspectRatio: 1.0,
  //       child: CircularProgressIndicator(
  //         backgroundColor: Colors.black12,
  //         color: Colors.black26,
  //       ),
  //     ),
  //   );
  // }

  // Widget buildConnectButton(BuildContext context) {
  //   return Row(children: [
  //     if (_isConnecting || _isDisconnecting) buildSpinner(context),
  //     TextButton(
  //         onPressed: _isConnecting
  //             ? onCancelPressed
  //             : (isConnected ? onDisconnectPressed : onConnectPressed),
  //         child: Text(
  //           _isConnecting ? "CANCEL" : (isConnected ? "DISCONNECT" : "CONNECT"),
  //           style: Theme.of(context)
  //               .primaryTextTheme
  //               .labelLarge
  //               ?.copyWith(color: Colors.black),
  //         ))
  //   ]);
  // }

  // final List<String> names = [
  //   "BMS_state",
  //   "Battery_configuration",
  //   "Battery_voltage",
  //   "Battery_current",
  //   "Battery_temperature",
  //   "Battery_cycle_count",
  //   "Battery_health_status",
//    "BMS_fault",
//    "Package_total_capacity",
//    "Package_remaining_capacity",
//    "cell1_voltage",
//    "cell2_voltage",
//   "cell3_voltage",
//    "cell4_voltage",
//    "cell5_voltage",
//    "cell6_voltage",
//    "cell7_voltage",
//    "cell8_voltage",
//    "cell9_voltage",
//    "cell10_voltage",
//    "cell11_voltage",
//    "cell12_voltage",
//    "cell13_voltage",
//    "cell14_voltage",
//    "cell15_voltage",
//    "cell16_voltage",
//    "Battery_discharge",
//    "Battery_full_charge",
//    "Charging_Porf_cc",
//    "Charging_Porf_cv"
//  ];
//
//  @override
//  Widget build(BuildContext context) {
//    final Size size = MediaQuery.of(context).size;
//    return ScaffoldMessenger(
//      child: Scaffold(
//        appBar: AppBar(
//          flexibleSpace: Container(
//            decoration: BoxDecoration(
//                gradient: LinearGradient(
//                    colors: [Colors.white, Colors.grey.shade500],
//                    begin: Alignment.topCenter,
//                    end: Alignment.bottomCenter)),
//          ),
//          title: Text(widget.device.platformName),
//          actions: [buildConnectButton(context)],
//        ),
//        body: ListView.builder(
//            itemCount: names.length,
//            itemBuilder: (BuildContext context, int index) {
//              String name = names[index];
//              // String uuid = uuids[name] ?? '';
//              String value = data[name] ?? 'NA';
//              return Container(
//                color: Colors.white,
//                padding: EdgeInsets.all(size.height * 0.01),
//                child: Container(
//                  // color: CustomColors.mainColor_1,
//                  decoration: BoxDecoration(
//                      borderRadius: BorderRadius.circular(10),
//                      color: CustomColors.mainColor_3),
//                  child: ListTile(
//                    title: Text(
//                      names[index],
//                      style: TextStyle(
//                          color: Colors.white, fontWeight: FontWeight.bold),
//                    ),
//                    trailing: Text(value),
//                  ),
//                ),
//              );
//            }),
//      ),
//    );
//  }
//}
