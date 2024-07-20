import 'dart:async';
import 'dart:typed_data';
import 'package:algo_safe/constants/uuid_list.dart';
import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';
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
  int? rssi;
  BluetoothConnectionState connection_state =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> services = [];
  bool is_discovering_services = false;
  bool is_connecting = false;
  bool is_disconnecting = false;
  var BMS_current_state = 0; // 125: idle, 4: charging, 3:discharging
  var AlgoPAD_current_state = 0; // 1: idle 2: charging
  var product_state = 0;

  late StreamSubscription<BluetoothConnectionState>
      connection_state_subscription;
  late StreamSubscription<bool> is_connecting_subscription;
  late StreamSubscription<bool> is_disconnecting_subscription;
  int BMS_read_write_selector = 0;
  int AlgoX_read_write_selector = 0;

  Map<String, String> data_fetched = {};

  final Map<String, TextEditingController> BMS_write_controller = {
    for (var key in uuids.keys) key: TextEditingController()
  };

  void delayed_refresh_function() {
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        on_refresh_pressed();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    delayed_refresh_function();

    connection_state_subscription =
        widget.device.connectionState.listen((state) async {
      connection_state = state;
      if (state == BluetoothConnectionState.connected) {
        services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && rssi == null) {
        rssi = await widget.device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    is_connecting_subscription = widget.device.is_connecting.listen((value) {
      is_connecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    is_disconnecting_subscription =
        widget.device.is_disconnecting.listen((value) {
      is_disconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    connection_state_subscription.cancel();
    is_connecting_subscription.cancel();
    is_disconnecting_subscription.cancel();
    super.dispose();
  }

  bool get is_connected {
    return connection_state == BluetoothConnectionState.connected;
  }

  Future on_connect_pressed() async {
    try {
      await widget.device.connect_and_update_stream();
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, pretty_exception("Connect Error:", e),
            success: false);
      }
    }
  }

  Future on_cancel_pressed() async {
    try {
      await widget.device.disconnect_and_update_stream(queue: false);
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, pretty_exception("Cancel Error:", e),
          success: false);
    }
  }

  Future on_disconnect_pressed() async {
    try {
      await widget.device.disconnect_and_update_stream();
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, pretty_exception("Disconnect Error:", e),
          success: false);
    }
  }

  Future on_refresh_pressed() async {
    try {
      is_discovering_services = true;
      setState(() {});
      services = await widget.device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (uuids.containsValue(characteristic.uuid.toString())) {
            subscribe_to_characteristic(characteristic);
          }
        }
      }
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, pretty_exception("Discover Services Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        is_discovering_services = false;
      });
    }
  }

  List<Widget> build_service_tiles(BuildContext context, BluetoothDevice d) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map((c) => build_characteristic_tile(c))
                .toList(),
          ),
        )
        .toList();
  }

  CharacteristicTile build_characteristic_tile(BluetoothCharacteristic c) {
    return CharacteristicTile(
      characteristic: c,
      descriptorTiles:
          c.descriptors.map((d) => DescriptorTile(descriptor: d)).toList(),
      descriptors: [],
    );
  }

  Widget build_spinner(BuildContext context) {
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

  Future on_discover_services_pressed() async {
    if (mounted) {
      setState(() {
        is_discovering_services = true;
      });
    }
    try {
      services = await widget.device.discoverServices();
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, pretty_exception("Discover Services Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        is_discovering_services = false;
      });
    }
  }

  int parse_uint16(List<int> value) {
    final ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));
    return byteData.getUint16(0, Endian.little);
  }

  Future<void> subscribe_to_characteristic(
      BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    characteristic.value.listen((value) {
      String characteristic_key = uuids.keys
          .firstWhere((key) => uuids[key] == characteristic.uuid.toString());

      if (value.isNotEmpty) {
        String parsed_value;
        if (value.length == 1) {
          // uint8 parsing
          parsed_value = value[0].toString();
        } else if (value.length >= 2) {
          // uint16 parsing
          parsed_value = parse_uint16(value).toString();
        } else {
          parsed_value = 'Unknown value';
        }

        setState(() {
          data_fetched[characteristic_key] = parsed_value;
        });
      }
    });
  }

  Widget BMS_state_display() {
    Widget temp = BMS_idle_widget();
    var state_value = data_fetched["BMS_state"];
    print(state_value);
    if (state_value is String) {
      BMS_current_state = int.tryParse(state_value) ?? 0;
    } else if (state_value is int) {
      // ignore: cast_from_null_always_fails
      BMS_current_state = state_value as int;
    } else {
      BMS_current_state = 0;
    }

    switch (BMS_current_state) {
      case 1:
      case 2:
      case 5:
        temp = BMS_idle_widget();
        break;

      case 4:
        temp = BMS_charging_widget();
        break;

      case 3:
        temp = BMS_discharging_widget();
        break;

      default:
        temp = BMS_idle_widget();
        break;
    }
    return temp;
  }

  Widget AlgoPAD_state_display() {
    Widget temp = AlgoPAD_idle_widget();
    var state_value = data_fetched["AlgoPAD_state"]; // AlgoPAD Status
    print(state_value);
    if (state_value is String) {
      AlgoPAD_current_state = int.tryParse(state_value) ?? 0;
    } else if (state_value is int) {
      // ignore: cast_from_null_always_fails
      AlgoPAD_current_state = state_value as int;
    } else {
      AlgoPAD_current_state = 0;
    }

    switch (AlgoPAD_current_state) {
      case 1:
        temp = AlgoPAD_idle_widget();
        break;

      case 2:
        temp = AlgoPAD_charging_widget();
        break;

      default:
        temp = AlgoPAD_idle_widget();
        break;
    }
    return temp;
  }

  Future write_characteristic(
      BluetoothCharacteristic characteristic, String value) async {
    List<int> bytes = value.codeUnits;
    await characteristic.write(bytes, withoutResponse: true);
  }

  Future<void> on_write_pressed(String characteristic_name) async {
    String? characteristic_uuid = uuids[characteristic_name];
    String value = BMS_write_controller[characteristic_name]?.text ?? '';

    // Validate input values
    if (value.isEmpty || characteristic_uuid == null) {
      // Snackbar.show(
      //   ABC.c,
      //   "$characteristic_name Write: No value provided or invalid UUID",
      //   success: false,
      // );
      return; // Skip if no value is provided or UUID is invalid
    }

    List<BluetoothCharacteristic> target_characteristics = [];

    // Find all target characteristics by UUID
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == characteristic_uuid) {
          target_characteristics.add(characteristic);
        }
      }
    }

    if (target_characteristics.isNotEmpty) {
      for (var target_characteristic in target_characteristics) {
        try {
          // Check if the characteristic supports write without response
          if (target_characteristic.properties.writeWithoutResponse) {
            await target_characteristic.write(value.codeUnits,
                withoutResponse: true);
            // Snackbar.show(ABC.c,
            //     "$characteristic_name Write to ${target_characteristic.uuid}: Success",
            //     success: true);
          }
          // Check if the characteristic supports write with response
          else if (target_characteristic.properties.write) {
            await target_characteristic.write(value.codeUnits,
                withoutResponse: false);
            // Snackbar.show(ABC.c,
            //     "$characteristic_name Write to ${target_characteristic.uuid}: Success",
            //     success: true);
          }
          // Characteristic is not writable
          else {
            // Snackbar.show(
            //   ABC.c,
            //   "$characteristic_name Write to ${target_characteristic.uuid}: Characteristic not writable",
            //   success: false,
            // );
          }
        } catch (e) {
          // Snackbar.show(
          //   ABC.c,
          //   "$characteristic_name Write to ${target_characteristic.uuid}: Error - $e",
          //   success: false,
          // );
        }
      }
    } else {
      // Snackbar.show(
      //   ABC.c,
      //   "$characteristic_name Write: Characteristics not found",
      //   success: false,
      // );
    }
  }

  Map<String, List<String>> drop_down_items = {
    "Battery_cell_nos": ["2", "4", "6", "8", "10", "12", "14", "16"],
    "Charging_type": ["Fast Charge", "Balance Charge", "Storage Charge"],
    "Cell_Chemistry": ["LiPo", "LiIon", "LiHv", "LiFe"],
    "Algox_Cell_Nos": ["2", "4", "6", "8", "10", "12", "14", "16"],
  };

  final Map<String, double> slider_values = {
    "Algox_Current": 0.0,
    "Battery_constant_current": 0.0,
    "Battery_peak_current": 0.0,
    "Battery_max_voltage": 0.0,
    "Battery_min_voltage": 0.0,
    "Battery_operating_temperature": 0.0,
  };

  Map<String, List<double>> slider_min_max = {
    "Algox_Current": [0.0, 100.0],
    "Battery_constant_current": [0.0, 180.0],
    "Battery_peak_current": [0.0, 180.0],
    "Battery_max_voltage": [0.0, 4350.0],
    "Battery_min_voltage": [0.0, 2500.0],
    "Battery_operating_temperature": [0.0, 80.0],
  };

  Map<String, int> slider_divisions = {
    "Algox_Current": 20,
    "Battery_constant_current": 90,
    "Battery_peak_current": 90,
    "Battery_max_voltage": 87,
    "Battery_min_voltage": 50,
    "Battery_operating_temperature": 80,
  };

  Map<String, bool> toggle_values = {
    "Start_Charging": false,
    "Battery_DSG_C": false,
    "Battery_CHG_C": false,
  };

  final BMS_form_key = GlobalKey<FormState>();

  Widget BMS_write_screen() {
    final Size size = MediaQuery.of(context).size;
    return Expanded(
      child: Form(
        key: BMS_form_key,
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.height * 0.01),
                color: CustomColors.mainColor_1,
              ),
              child: ExpansionTile(
                title: Text(
                  'Compulsory Fields',
                  style: TextStyle(color: Colors.white),
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child:
                        build_drop_down_for_characteristic("Battery_cell_nos"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_text_field_for_characteristic("Battery_id"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_text_field_for_characteristic("BMS_id"),
                  ),
                  SizedBox(height: size.height * 0.01),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.height * 0.01),
                color: CustomColors.mainColor_1,
              ),
              child: ExpansionTile(
                title: Text(
                  'Default Values',
                  style: TextStyle(color: Colors.white),
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_slider_for_characteristic("Battery_capacity"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_slider_for_characteristic("Battery_constant_current"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_slider_for_characteristic("Battery_peak_current"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_slider_for_characteristic("Battery_max_voltage"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_slider_for_characteristic("Battery_min_voltage"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_slider_for_characteristic(
                        "Battery_operating_temperature"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_toggle_for_characteristic("Battery_DSG_C"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_toggle_for_characteristic("DSG_OverCurrent"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_toggle_for_characteristic("CHG_OverVoltage"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_toggle_for_characteristic("DSG_OverTemperature"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_toggle_for_characteristic("CHG_OverTemperature"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_toggle_for_characteristic("DSG_UnderVoltage"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_toggle_for_characteristic("Battery_CHG_C"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_slider_for_characteristic("SOC"),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.02),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.mainColor_1),
              onPressed: () {
                if (BMS_form_key.currentState!.validate()) {
                  BMS_on_send_all_pressed();
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

  final AlgoX_form_key = GlobalKey<FormState>();

  Widget AlgoX_write_screen() {
    final Size size = MediaQuery.of(context).size;
    return Expanded(
      child: Form(
        key: AlgoX_form_key,
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.height * 0.01),
                color: CustomColors.mainColor_1,
              ),
              child: ExpansionTile(
                title: Text(
                  'Compulsory Fields',
                  style: TextStyle(color: Colors.white),
                ),
                initiallyExpanded: false,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.all(4.0),
                  //   child: build_drop_down_for_characteristic("Charging_type"),
                  // ),
                  // SizedBox(height: size.height * 0.01),
                  // Padding(
                  //   padding: const EdgeInsets.all(4.0),
                  //   child: build_drop_down_for_characteristic("Cell_Chemistry"),
                  // ),
                  // SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_drop_down_for_characteristic("Algox_Cell_Nos"),
                  ),
                  SizedBox(height: size.height * 0.01),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.height * 0.01),
                color: CustomColors.mainColor_1,
              ),
              child: ExpansionTile(
                title: Text(
                  'Default Values',
                  style: TextStyle(color: Colors.white),
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_slider_for_characteristic("Algox_Current"),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: build_toggle_for_characteristic("Start_Charging"),
                  ),
                  SizedBox(height: size.height * 0.01),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.02),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.mainColor_1),
              onPressed: () {
                if (AlgoX_form_key.currentState!.validate()) {
                  AlgoX_on_send_all_pressed();
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

  Widget build_text_field_for_characteristic(String key,
      {bool is_required = false}) {
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
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                controller: BMS_write_controller[key],
                decoration: InputDecoration(
                  labelText: key.replaceAll('_', ' '),
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                validator: is_required
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter $key';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
            // SizedBox(width: 8),
            // IconButton(
            //   color: Colors.white,
            //   onPressed: () => on_write_pressed(key),
            //   icon: Icon(Icons.save),
            // ),
          ],
        ),
      ),
    );
  }

  Widget build_drop_down_for_characteristic(String key) {
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
                value: BMS_write_controller[key]?.text.isEmpty == true
                    ? null
                    : BMS_write_controller[key]?.text,
                onChanged: (new_value) {
                  setState(() {
                    BMS_write_controller[key]?.text = new_value!;
                  });
                },
                items: drop_down_items[key]?.map((String value) {
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
            // SizedBox(width: 8),
            // IconButton(
            //   color: Colors.white,
            //   onPressed: () => on_write_pressed(key),
            //   icon: Icon(Icons.save),
            // ),
          ],
        ),
      ),
    );
  }

  Widget build_slider_for_characteristic(String key) {
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
                    '${key}: ${slider_values[key]?.toStringAsFixed(1)}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            double new_value = slider_values[key]! - 1;
                            if (new_value >= slider_min_max[key]![0]) {
                              slider_values[key] = new_value;
                              BMS_write_controller[key]?.text =
                                  new_value.toStringAsFixed(1);
                            }
                          });
                        },
                      ),
                      Spacer(),
                      Container(
                        width: size.width * 0.65,
                        child: Slider(
                          activeColor: Colors.blueAccent,
                          value: slider_values[key] ?? 0.0,
                          min: slider_min_max[key]?.first ?? 0.0,
                          max: slider_min_max[key]?.last ?? 100.0,
                          divisions: slider_divisions[key] ?? 10,
                          label:
                              (slider_values[key]?.toStringAsFixed(1) ?? '0.0'),
                          onChanged: (new_value) {
                            setState(() {
                              slider_values[key] = new_value;
                              BMS_write_controller[key]?.text =
                                  new_value.toStringAsFixed(1);
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
                            double new_value = slider_values[key]! + 1;
                            if (new_value <= slider_min_max[key]![1]) {
                              slider_values[key] = new_value;
                              BMS_write_controller[key]?.text =
                                  new_value.toStringAsFixed(1);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // SizedBox(width: 8),
            // IconButton(
            //   color: Colors.white,
            //   onPressed: () => on_write_pressed(key),
            //   icon: Icon(Icons.save),
            // ),
          ],
        ),
      ),
    );
  }

  Widget build_toggle_for_characteristic(String key) {
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
                    value: toggle_values[key] ?? false,
                    onChanged: (bool new_value) {
                      setState(() {
                        toggle_values[key] = new_value;
                        BMS_write_controller[key]?.text = new_value ? '1' : '0';
                      });
                    },
                  ),
                ],
              ),
            ),
            // SizedBox(width: 8),
            // IconButton(
            //   color: Colors.white,
            //   onPressed: () => on_write_pressed(key),
            //   icon: Icon(Icons.save),
            // ),
          ],
        ),
      ),
    );
  }

  Map<String, String> BMS_last_sent_values = {};

  Future<void> BMS_on_send_all_pressed() async {
    bool all_success = true;
    String summary_message = '';

    for (String characteristic_name in uuid_algoBMS_write.keys) {
      String? characteristic_uuid = uuid_algoBMS_write[characteristic_name];
      String value = BMS_write_controller[characteristic_name]?.text ?? '';

      if (value.isEmpty || characteristic_uuid == null) {
        summary_message +=
            '$characteristic_name Write: No value provided or invalid UUID\n';
        all_success = false;
        continue;
      }

      // Check if the value has changed since the last send
      if (BMS_last_sent_values[characteristic_name] == value) {
        summary_message +=
            '$characteristic_name Write: Value unchanged, not sending\n';
        continue;
      }

      BluetoothCharacteristic? target_characteristic;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristic_uuid) {
            target_characteristic = characteristic;
            break;
          }
        }
        if (target_characteristic != null) break;
      }

      if (target_characteristic != null) {
        try {
          if (target_characteristic.properties.writeWithoutResponse) {
            await target_characteristic.write(value.codeUnits,
                withoutResponse: true);
            summary_message += '$characteristic_name Write: Success\n';
          } else if (target_characteristic.properties.write) {
            await target_characteristic.write(value.codeUnits,
                withoutResponse: false);
            summary_message += '$characteristic_name Write: Success\n';
          } else {
            summary_message +=
                '$characteristic_name Write: Characteristic not writable\n';
            all_success = false;
          }
          // Update the last sent value after a successful send
          BMS_last_sent_values[characteristic_name] = value;
        } catch (e) {
          summary_message += '$characteristic_name Write: Error - $e\n';
          all_success = false;
        }
      } else {
        summary_message +=
            '$characteristic_name Write: Characteristic not found\n';
        all_success = false;
      }
    }

    Snackbar.show(ABC.c, summary_message, success: all_success);
  }

  Map<String, String> AlgoX_last_sent_values = {};

  Future<void> AlgoX_on_send_all_pressed() async {
    bool all_success = true;
    String summary_message = '';

    for (String characteristic_name in uuid_algoX_write.keys) {
      String? characteristic_uuid = uuid_algoX_write[characteristic_name];
      String value = BMS_write_controller[characteristic_name]?.text ?? '';

      if (value.isEmpty || characteristic_uuid == null) {
        summary_message +=
            '$characteristic_name Write: No value provided or invalid UUID\n';
        all_success = false;
        continue;
      }

      // Check if the value has changed since the last send
      if (AlgoX_last_sent_values[characteristic_name] == value) {
        summary_message +=
            '$characteristic_name Write: Value unchanged, not sending\n';
        continue;
      }

      BluetoothCharacteristic? target_characteristic;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristic_uuid) {
            target_characteristic = characteristic;
            break;
          }
        }
        if (target_characteristic != null) break;
      }

      if (target_characteristic != null) {
        try {
          if (target_characteristic.properties.writeWithoutResponse) {
            await target_characteristic.write(value.codeUnits,
                withoutResponse: true);
            summary_message += '$characteristic_name Write: Success\n';
          } else if (target_characteristic.properties.write) {
            await target_characteristic.write(value.codeUnits,
                withoutResponse: false);
            summary_message += '$characteristic_name Write: Success\n';
          } else {
            summary_message +=
                '$characteristic_name Write: Characteristic not writable\n';
            all_success = false;
          }
          // Update the last sent value after a successful send
          AlgoX_last_sent_values[characteristic_name] = value;
        } catch (e) {
          summary_message += '$characteristic_name Write: Error - $e\n';
          all_success = false;
        }
      } else {
        summary_message +=
            '$characteristic_name Write: Characteristic not found\n';
        all_success = false;
      }
    }

    Snackbar.show(ABC.c, summary_message, success: all_success);
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

  //     for (var service in services) {
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

  Widget BMS_state_show() {
    final Size size = MediaQuery.of(context).size;
    var state_value = data_fetched["BMS_state"];
    if (state_value is String) {
      BMS_current_state = int.tryParse(state_value) ?? 0;
    } else if (state_value is int) {
      // ignore: cast_from_null_always_fails
      BMS_current_state = state_value as int;
    } else {
      BMS_current_state = 0;
    }

    switch (BMS_current_state) {
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
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                          Text(
                            "IDLE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                          Spacer(),
                          Text(
                            "AlgoBMS",
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            width: size.width * 0.01,
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
                          Lottie.asset("assets/gifs/charging.json"),
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                          Text(
                            "CHARGE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                          Spacer(),
                          Text(
                            "AlgoBMS",
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            width: size.width * 0.01,
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
                          // Icon(Icons.battery_alert_sharp),
                          Lottie.asset("assets/gifs/charging.json",
                              reverse: true),
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                          Text(
                            "DISCHARGE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                          Spacer(),
                          Text(
                            "AlgoBMS",
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            width: size.width * 0.01,
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
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                          Icon(Icons.power_off),
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                          Text(
                            "MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                          Spacer(),
                          Text(
                            "Device",
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                        ],
                      ),
                    );
                  })),
        );
    }
  }

  Widget AlgoPAD_state_show() {
    final Size size = MediaQuery.of(context).size;
    var state_value = data_fetched["AlgoPAD_state"];
    if (state_value is String) {
      AlgoPAD_current_state = int.tryParse(state_value) ?? 0;
    } else if (state_value is int) {
      // ignore: cast_from_null_always_fails
      AlgoPAD_current_state = state_value as int;
    } else {
      AlgoPAD_current_state = 0;
    }

    switch (AlgoPAD_current_state) {
      case 1: // Idle Mode
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
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                          Text(
                            "IDLE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                          Spacer(),
                          Text(
                            "AlgoPAD",
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                        ],
                      ),
                    );
                  })),
        );

      case 2: // Charging Mode
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
                          Lottie.asset("assets/gifs/charging.json"),
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                          Text(
                            "CHARGE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                          Spacer(),
                          Text(
                            "AlgoPAD",
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            width: size.width * 0.01,
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
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                          Text(
                            "IDLE MODE",
                            style: TextStyle(fontSize: 20),
                          ),
                          Spacer(),
                          Text(
                            "AlgoPAD",
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            width: size.width * 0.01,
                          ),
                        ],
                      ),
                    );
                  })),
        );
    }
  }

  Widget BMS_navigation_bar() {
    // final Size size = MediaQuery.of(context).size;
    var nav_value = data_fetched["BMS_state"];
    if (nav_value is String) {
      BMS_current_state = int.tryParse(nav_value) ?? 0;
    } else if (nav_value is int) {
      // ignore: cast_from_null_always_fails
      BMS_current_state = nav_value as int;
    } else {
      BMS_current_state = 0;
    }

    switch (BMS_current_state) {
      case 1:
      case 2:
      case 5:
        return BMS_bottom_navigation_bar();

      case 4:
        return SizedBox.shrink();

      case 3:
        return SizedBox.shrink();

      default:
        return BMS_bottom_navigation_bar();
    }
  }

  Widget BMS_bottom_navigation_bar() {
    final Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.075,
      decoration: BoxDecoration(
          color: CustomColors.mainColor_1,
          borderRadius: BorderRadius.circular(20)),
      child: Theme(
        data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return TextStyle(
                    color: Colors.grey); // Color for selected label
              }
              return TextStyle(
                  color: Colors.white); // Color for unselected labels
            },
          ),
        )),
        child: NavigationBar(
          indicatorColor: CustomColors.mainColor_3,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          height: size.height * 0.1,
          selectedIndex: BMS_read_write_selector,
          onDestinationSelected: (int index) {
            setState(() {
              BMS_read_write_selector = index;
            });
          },
          destinations: <NavigationDestination>[
            NavigationDestination(
                icon: Icon(
                  Icons.my_library_books,
                  color: Colors.white,
                ),
                label: "Data Monitoring"),
            NavigationDestination(
                icon: Icon(Icons.edit, color: Colors.white),
                label: "Data Configuration")
          ],
        ),
      ),
    );
  }

  Widget AlgoX_bottom_navigation_bar() {
    final Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.075,
      decoration: BoxDecoration(
          color: CustomColors.mainColor_1,
          borderRadius: BorderRadius.circular(20)),
      child: Theme(
        data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return TextStyle(
                    color: Colors.grey); // Color for selected label
              }
              return TextStyle(
                  color: Colors.white); // Color for unselected labels
            },
          ),
        )),
        child: NavigationBar(
          indicatorColor: CustomColors.mainColor_3,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          height: size.height * 0.1,
          selectedIndex: AlgoX_read_write_selector,
          onDestinationSelected: (int index) {
            setState(() {
              AlgoX_read_write_selector = index;
            });
          },
          destinations: <NavigationDestination>[
            NavigationDestination(
                icon: Icon(
                  Icons.my_library_books,
                  color: Colors.white,
                ),
                label: "Data Monitoring"),
            NavigationDestination(
                icon: Icon(Icons.edit, color: Colors.white),
                label: "Data Configuration")
          ],
        ),
      ),
    );
  }

  Widget build_connect_button(BuildContext context) {
    return Row(children: [
      if (is_connecting || is_disconnecting) build_spinner(context),
      TextButton(
          onPressed: is_connecting
              ? on_cancel_pressed
              : (is_connected ? on_disconnect_pressed : on_connect_pressed),
          child: Text(
            is_connecting
                ? "CANCEL"
                : (is_connected ? "DISCONNECT" : "CONNECT"),
            style: Theme.of(context)
                .primaryTextTheme
                .labelLarge
                ?.copyWith(color: Colors.white),
          ))
    ]);
  }

  Widget BMS_idle_widget() {
    final Size size = MediaQuery.of(context).size;
    double batteryVoltage = data_fetched["Battery_voltage"] != null
        ? double.parse(data_fetched["Battery_voltage"]!)
        : 0.0;

    double batteryTemperature = data_fetched["Battery_temperature"] != null
        ? double.parse(data_fetched["Battery_temperature"]!)
        : 0.0;

    double batteryHealthStatus = data_fetched["Battery_health_status"] != null
        ? double.parse(data_fetched["Battery_health_status"]!)
        : 0.0;

    double packageTotalCapacity = data_fetched["Package_total_capacity"] != null
        ? double.parse(data_fetched["Package_total_capacity"]!)
        : 0.0;

    double batteryCycleCount = data_fetched["Battery_cycle_count"] != null
        ? double.parse(data_fetched["Battery_cycle_count"]!)
        : 0.0;

    double bmsFault = data_fetched["BMS_fault"] != null
        ? double.parse(data_fetched["BMS_fault"]!)
        : 0.0;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
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

  Widget AlgoPAD_idle_widget() {
    final Size size = MediaQuery.of(context).size;

    double droneStatus = data_fetched["Drone_status"] != null
        ? double.parse(data_fetched["Drone_status"]!)
        : 0.0;

    double chargingStatus = data_fetched["Charging_status"] != null
        ? double.parse(data_fetched["Charging_status"]!)
        : 0.0;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.height * 0.01),
                  color: CustomColors.mainColor_3),
              child: ListTile(
                title: const Text(
                  'Drone Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(droneStatus == 1 ? 'Present' : "Not Present",
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
                  'Charging Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                trailing: Text(chargingStatus == 1 ? "Active" : "Inactive",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: size.height * 0.018)),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
          ],
        ),
      ),
    );
  }

  Widget AlgoX_charging_widget() {
    final Size size = MediaQuery.of(context).size;

    double batteryVoltage = data_fetched["Battery_voltage"] != null
        ? double.parse(data_fetched["Battery_voltage"]!)
        : 0.0;

    double batteryCurrent = data_fetched["Battery_current"] != null
        ? double.parse(data_fetched["Battery_current"]!)
        : 0.0;

    // double cell1Voltage = data_fetched["cell1_voltage"] != null
    //     ? double.parse(data_fetched["cell1_voltage"]!)
    //     : 0.0;

    // double cell2Voltage = data_fetched["cell2_voltage"] != null
    //     ? double.parse(data_fetched["cell2_voltage"]!)
    //     : 0.0;

    // double cell3Voltage = data_fetched["cell3_voltage"] != null
    //     ? double.parse(data_fetched["cell3_voltage"]!)
    //     : 0.0;

    // double cell4Voltage = data_fetched["cell4_voltage"] != null
    //     ? double.parse(data_fetched["cell4_voltage"]!)
    //     : 0.0;

    // double cell5Voltage = data_fetched["cell5_voltage"] != null
    //     ? double.parse(data_fetched["cell5_voltage"]!)
    //     : 0.0;

    // double cell6Voltage = data_fetched["cell6_voltage"] != null
    //     ? double.parse(data_fetched["cell6_voltage"]!)
    //     : 0.0;

    // double cell7Voltage = data_fetched["cell7_voltage"] != null
    //     ? double.parse(data_fetched["cell7_voltage"]!)
    //     : 0.0;

    // double cell8Voltage = data_fetched["cell8_voltage"] != null
    //     ? double.parse(data_fetched["cell8_voltage"]!)
    //     : 0.0;

    // double cell9Voltage = data_fetched["cell9_voltage"] != null
    //     ? double.parse(data_fetched["cell9_voltage"]!)
    //     : 0.0;

    // double cell10Voltage = data_fetched["cell10_voltage"] != null
    //     ? double.parse(data_fetched["cell10_voltage"]!)
    //     : 0.0;

    // double cell11Voltage = data_fetched["cell11_voltage"] != null
    //     ? double.parse(data_fetched["cell11_voltage"]!)
    //     : 0.0;

    // double cell12Voltage = data_fetched["cell12_voltage"] != null
    //     ? double.parse(data_fetched["cell12_voltage"]!)
    //     : 0.0;

    // double cell13Voltage = data_fetched["cell13_voltage"] != null
    //     ? double.parse(data_fetched["cell13_voltage"]!)
    //     : 0.0;

    // double cell14Voltage = data_fetched["cell14_voltage"] != null
    //     ? double.parse(data_fetched["cell14_voltage"]!)
    //     : 0.0;

    // double cell15Voltage = data_fetched["cell15_voltage"] != null
    //     ? double.parse(data_fetched["cell15_voltage"]!)
    //     : 0.0;

    // double cell16Voltage = data_fetched["cell16_voltage"] != null
    //     ? double.parse(data_fetched["cell16_voltage"]!)
    //     : 0.0;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
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
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell1 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell1Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell2 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell2Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell3 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell3Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell4 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell4Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell5 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell5Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell6 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell6Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell7 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell7Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell8 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell8Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell9 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text((cell9Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell10 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text(
            //         (cell10Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell11 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text(
            //         (cell11Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell12 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text(
            //         (cell12Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell13 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text(
            //         (cell13Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell14 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text(
            //         (cell14Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell15 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text(
            //         (cell15Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(size.height * 0.01),
            //       color: CustomColors.mainColor_3),
            //   child: ListTile(
            //     title: const Text(
            //       'Cell16 Voltage',
            //       style: TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.white),
            //     ),
            //     trailing: Text(
            //         (cell16Voltage * 0.001).toStringAsFixed(3) + ' V',
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //             fontSize: size.height * 0.018)),
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.01,
            // ),
          ],
        ),
      ),
    );
  }

  Widget AlgoPAD_charging_widget() {
    final Size size = MediaQuery.of(context).size;

    double batteryVoltage = data_fetched["Battery_voltage"] != null
        ? double.parse(data_fetched["Battery_voltage"]!)
        : 0.0;

    double batteryCurrent = data_fetched["Battery_current"] != null
        ? double.parse(data_fetched["Battery_current"]!)
        : 0.0;

    double batteryHealthStatus = data_fetched["Battery_health_status"] != null
        ? double.parse(data_fetched["Battery_health_status"]!)
        : 0.0;

    double packageRemainingCapacity =
        data_fetched["Package_remaining_capacity"] != null
            ? double.parse(data_fetched["Package_remaining_capacity"]!)
            : 0.0;

    double cell1Voltage = data_fetched["cell1_voltage"] != null
        ? double.parse(data_fetched["cell1_voltage"]!)
        : 0.0;

    double cell2Voltage = data_fetched["cell2_voltage"] != null
        ? double.parse(data_fetched["cell2_voltage"]!)
        : 0.0;

    double cell3Voltage = data_fetched["cell3_voltage"] != null
        ? double.parse(data_fetched["cell3_voltage"]!)
        : 0.0;

    double cell4Voltage = data_fetched["cell4_voltage"] != null
        ? double.parse(data_fetched["cell4_voltage"]!)
        : 0.0;

    double cell5Voltage = data_fetched["cell5_voltage"] != null
        ? double.parse(data_fetched["cell5_voltage"]!)
        : 0.0;

    double cell6Voltage = data_fetched["cell6_voltage"] != null
        ? double.parse(data_fetched["cell6_voltage"]!)
        : 0.0;

    double cell7Voltage = data_fetched["cell7_voltage"] != null
        ? double.parse(data_fetched["cell7_voltage"]!)
        : 0.0;

    double cell8Voltage = data_fetched["cell8_voltage"] != null
        ? double.parse(data_fetched["cell8_voltage"]!)
        : 0.0;

    double cell9Voltage = data_fetched["cell9_voltage"] != null
        ? double.parse(data_fetched["cell9_voltage"]!)
        : 0.0;

    double cell10Voltage = data_fetched["cell10_voltage"] != null
        ? double.parse(data_fetched["cell10_voltage"]!)
        : 0.0;

    double cell11Voltage = data_fetched["cell11_voltage"] != null
        ? double.parse(data_fetched["cell11_voltage"]!)
        : 0.0;

    double cell12Voltage = data_fetched["cell12_voltage"] != null
        ? double.parse(data_fetched["cell12_voltage"]!)
        : 0.0;

    double cell13Voltage = data_fetched["cell13_voltage"] != null
        ? double.parse(data_fetched["cell13_voltage"]!)
        : 0.0;

    double cell14Voltage = data_fetched["cell14_voltage"] != null
        ? double.parse(data_fetched["cell14_voltage"]!)
        : 0.0;

    double cell15Voltage = data_fetched["cell15_voltage"] != null
        ? double.parse(data_fetched["cell15_voltage"]!)
        : 0.0;

    double cell16Voltage = data_fetched["cell16_voltage"] != null
        ? double.parse(data_fetched["cell16_voltage"]!)
        : 0.0;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
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
          ],
        ),
      ),
    );
  }

  Widget BMS_charging_widget() {
    final Size size = MediaQuery.of(context).size;

    double batteryVoltage = data_fetched["Battery_voltage"] != null
        ? double.parse(data_fetched["Battery_voltage"]!)
        : 0.0;

    double batteryCurrent = data_fetched["Battery_current"] != null
        ? double.parse(data_fetched["Battery_current"]!)
        : 0.0;

    double batteryTemperature = data_fetched["Battery_temperature"] != null
        ? double.parse(data_fetched["Battery_temperature"]!)
        : 0.0;

    double batteryHealthStatus = data_fetched["Battery_health_status"] != null
        ? double.parse(data_fetched["Battery_health_status"]!)
        : 0.0;

    double packageTotalCapacity = data_fetched["Package_total_capacity"] != null
        ? double.parse(data_fetched["Package_total_capacity"]!)
        : 0.0;

    double packageRemainingCapacity =
        data_fetched["Package_remaining_capacity"] != null
            ? double.parse(data_fetched["Package_remaining_capacity"]!)
            : 0.0;

    double batteryFullCharge = data_fetched["Battery_full_charge"] != null
        ? double.parse(data_fetched["Battery_full_charge"]!)
        : 0.0;

    double chargingPorfileCV = data_fetched["Charging_Porfile_cv"] != null
        ? double.parse(data_fetched["Charging_Porfile_cv"]!)
        : 0.0;

    double chargingPorfileCC = data_fetched["Charging_Porfile_cc"] != null
        ? double.parse(data_fetched["Charging_Porfile_cc"]!)
        : 0.0;

    double cell1Voltage = data_fetched["cell1_voltage"] != null
        ? double.parse(data_fetched["cell1_voltage"]!)
        : 0.0;

    double cell2Voltage = data_fetched["cell2_voltage"] != null
        ? double.parse(data_fetched["cell2_voltage"]!)
        : 0.0;

    double cell3Voltage = data_fetched["cell3_voltage"] != null
        ? double.parse(data_fetched["cell3_voltage"]!)
        : 0.0;

    double cell4Voltage = data_fetched["cell4_voltage"] != null
        ? double.parse(data_fetched["cell4_voltage"]!)
        : 0.0;

    double cell5Voltage = data_fetched["cell5_voltage"] != null
        ? double.parse(data_fetched["cell5_voltage"]!)
        : 0.0;

    double cell6Voltage = data_fetched["cell6_voltage"] != null
        ? double.parse(data_fetched["cell6_voltage"]!)
        : 0.0;

    double cell7Voltage = data_fetched["cell7_voltage"] != null
        ? double.parse(data_fetched["cell7_voltage"]!)
        : 0.0;

    double cell8Voltage = data_fetched["cell8_voltage"] != null
        ? double.parse(data_fetched["cell8_voltage"]!)
        : 0.0;

    double cell9Voltage = data_fetched["cell9_voltage"] != null
        ? double.parse(data_fetched["cell9_voltage"]!)
        : 0.0;

    double cell10Voltage = data_fetched["cell10_voltage"] != null
        ? double.parse(data_fetched["cell10_voltage"]!)
        : 0.0;

    double cell11Voltage = data_fetched["cell11_voltage"] != null
        ? double.parse(data_fetched["cell11_voltage"]!)
        : 0.0;

    double cell12Voltage = data_fetched["cell12_voltage"] != null
        ? double.parse(data_fetched["cell12_voltage"]!)
        : 0.0;

    double cell13Voltage = data_fetched["cell13_voltage"] != null
        ? double.parse(data_fetched["cell13_voltage"]!)
        : 0.0;

    double cell14Voltage = data_fetched["cell14_voltage"] != null
        ? double.parse(data_fetched["cell14_voltage"]!)
        : 0.0;

    double cell15Voltage = data_fetched["cell15_voltage"] != null
        ? double.parse(data_fetched["cell15_voltage"]!)
        : 0.0;

    double cell16Voltage = data_fetched["cell16_voltage"] != null
        ? double.parse(data_fetched["cell16_voltage"]!)
        : 0.0;

    double bmsFault = data_fetched["BMS_fault"] != null
        ? double.parse(data_fetched["BMS_fault"]!)
        : 0.0;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
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

  Widget BMS_discharging_widget() {
    final Size size = MediaQuery.of(context).size;

    double batteryVoltage = data_fetched["Battery_voltage"] != null
        ? double.parse(data_fetched["Battery_voltage"]!)
        : 0.0;

    double batteryCurrent = data_fetched["Battery_current"] != null
        ? double.parse(data_fetched["Battery_current"]!)
        : 0.0;

    double batteryTemperature = data_fetched["Battery_temperature"] != null
        ? double.parse(data_fetched["Battery_temperature"]!)
        : 0.0;

    double batteryHealthStatus = data_fetched["Battery_health_status"] != null
        ? double.parse(data_fetched["Battery_health_status"]!)
        : 0.0;

    double packageTotalCapacity = data_fetched["Package_total_capacity"] != null
        ? double.parse(data_fetched["Package_total_capacity"]!)
        : 0.0;

    double packageRemainingCapacity =
        data_fetched["Package_remaining_capacity"] != null
            ? double.parse(data_fetched["Package_remaining_capacity"]!)
            : 0.0;

    double batteryDischarge = data_fetched["Battery_discharge"] != null
        ? double.parse(data_fetched["Battery_discharge"]!)
        : 0.0;

    double bmsFault = data_fetched["BMS_fault"] != null
        ? double.parse(data_fetched["BMS_fault"]!)
        : 0.0;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
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

  Widget BMS_display() {
    final Size size = MediaQuery.of(context).size;
    final List<Widget> read_write_screens = [
      BMS_state_display(),
      BMS_write_screen()
    ];

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.white,
        toolbarHeight: size.height * 0.05,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
          child: Container(
            color: CustomColors.mainColor_1,
          ),
        ),
        title: Text(
          widget.device.platformName,
          style: TextStyle(color: Colors.white),
        ),
        actions: [build_connect_button(context)],
      ),
      body: Padding(
        padding: EdgeInsets.all(size.height * 0.01),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.01),
            BMS_state_show(),
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
            read_write_screens[BMS_read_write_selector]
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BMS_navigation_bar(),
      ),
    );
  }

  Widget AlgoX_display() {
    final Size size = MediaQuery.of(context).size;
    final List<Widget> read_write_screens = [
      AlgoX_charging_widget(),
      AlgoX_write_screen()
    ];

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.white,
        toolbarHeight: size.height * 0.05,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
          child: Container(
            color: CustomColors.mainColor_1,
          ),
        ),
        title: Text(
          widget.device.platformName,
          style: TextStyle(color: Colors.white),
        ),
        actions: [build_connect_button(context)],
      ),
      body: Padding(
        padding: EdgeInsets.all(size.height * 0.01),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.01),
            Container(
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
                              Lottie.asset("assets/gifs/charging.json"),
                              SizedBox(
                                width: size.width * 0.01,
                              ),
                              Text(
                                "CHARGE MODE",
                                style: TextStyle(fontSize: 20),
                              ),
                              Spacer(),
                              Text(
                                "AlgoX",
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(
                                width: size.width * 0.01,
                              ),
                            ],
                          ),
                        );
                      })),
            ),
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
            read_write_screens[AlgoX_read_write_selector]
          ],
        ),
      ),
      // bottomNavigationBar: Padding(
      //   padding: const EdgeInsets.all(8.0),
      //   child: AlgoX_bottom_navigation_bar(),
      // ),
    );
  }

  Widget AlgoPAD_display() {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.white,
        toolbarHeight: size.height * 0.05,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
          child: Container(
            color: CustomColors.mainColor_1,
          ),
        ),
        title: Text(
          widget.device.platformName,
          style: TextStyle(color: Colors.white),
        ),
        actions: [build_connect_button(context)],
      ),
      body: Padding(
        padding: EdgeInsets.all(size.height * 0.01),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.01),
            AlgoPAD_state_show(),
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
            AlgoPAD_state_display()
          ],
        ),
      ),
    );
  }

  Widget build_body() {
    Widget temp = BMS_display();
    var nav_value = data_fetched["Product_Id"];
    if (nav_value is String) {
      product_state = int.tryParse(nav_value) ?? 0;
    } else if (nav_value is int) {
      // ignore: cast_from_null_always_fails
      product_state = nav_value as int;
    } else {
      product_state = 0;
    }

    if (product_state == 2775) {
      temp = BMS_display();
    } else if (product_state == 4E85) {
      temp = AlgoX_display();
    } else if (product_state == 7595) {
      temp = AlgoPAD_display();
    }

    return temp;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(key: Snackbar.snackBarKeyC, child: build_body());
  }
}
