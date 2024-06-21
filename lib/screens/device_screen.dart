import 'dart:async';
import 'dart:typed_data';

import 'package:algo_safe/screens/display_data_screen.dart';
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

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
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
    return Container(
      // color: Colors.amber,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          '${widget.device.remoteId}',
          style: const TextStyle(fontSize: 20),
        ),
      ),
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
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e), success: false);
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
          onPressed: (){
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

  Widget buildDisplayData(BuildContext context) {
    BluetoothDevice connectedDevice = BluetoothDevice(remoteId: widget.device.remoteId);
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        FloatingActionButton.extended(
          backgroundColor: CustomColors.mainColor_3,
          onPressed: onRefreshPressed,
          label: Icon(Icons.refresh_rounded,color: Colors.white,)
        ),
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
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
        padding: EdgeInsets.all(size.height*0.01),
        child: Column(
          children: [
            buildRemoteId(context),
            SizedBox(height: size.height*0.01),
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade500],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)),
              child: ListTile(
                leading: buildRssiTile(context),
                title: Text(
                         'Device ${_connectionState.toString().split('.')[1]}.'),
                         trailing: buildGetServices(context),
              ),
            ),
            SizedBox(height: size.height*0.01),
            Container(child: buildMtuTile(context),decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade500],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)),),
                      // ..._buildServiceTiles(context, widget.device),
            // ElevatedButton(
            //   onPressed: onDiscoverServicesPressed,
            //   child: const Text("Discover Services"),
            // ),
            // _isDiscoveringServices
            //F     ? const CircularProgressIndicator()
            //     : const SizedBox.shrink(),
            // TextField(
            //   controller: _writeController,
            //   decoration: const InputDecoration(
            //     labelText: "Write Value",
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            // ElevatedButton(
            //   onPressed: onWritePressed,
            //   child: const Text("Write"),
            // ),
            SizedBox(
              height: size.height*0.01,
            ),
            Expanded(
              child: ListView(
                children: data.entries
                    .map((entry) => ListTile(
                      
                          title: Text(entry.key,style: TextStyle(fontWeight: FontWeight.bold),),
                          trailing: Text(entry.value, style: TextStyle(fontSize: size.height*0.02),),
                        ),
                        )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
          // body: SingleChildScrollView(
          //   child: Column(
          //     children: <Widget>[
          //       buildRemoteId(context),
          //       ListTile(
          //         leading: buildRssiTile(context),
          //         title: Text(
          //             'Device is ${_connectionState.toString().split('.')[1]}.'),
          //         trailing: buildGetServices(context),
          //       ),
          //       buildMtuTile(context),
          //       ..._buildServiceTiles(context, widget.device),
          //     ],
          //   ),
          // ),
          floatingActionButton: buildDisplayData(context),floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,),
    );
  }
}
