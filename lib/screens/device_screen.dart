import 'dart:async';
import 'dart:typed_data';
import 'package:algo_safe/constants/uuid_list.dart';
import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
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
  // Received Signal Strength Indicator for signal strength identification
  int? rssi;
  // checks for bluetooth connection state
  BluetoothConnectionState connection_state =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> services = [];

  // checks for connecting and disconnecting status
  bool is_discovering_services = false;
  bool is_connecting = false;
  bool is_disconnecting = false;

  // changes the state of the screen based on differernt values recieved
  var BMS_current_state = 0; // 125: idle, 4: charging, 3:discharging
  var AlgoPAD_current_state = 0; // 1: idle 2: charging
  var product_state = 0;

  // final controller = PageController(viewportFraction: 1, keepPage: true);
  bool onLastPage = false;
  int currentStep = 0;

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
      Snackbar.show(ABC.c, "Connection Status: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, pretty_exception("Connection Error:", e),
            success: false);
      }
    }
  }

  Future on_cancel_pressed() async {
    try {
      await widget.device.disconnect_and_update_stream(queue: false);
      Snackbar.show(ABC.c, "Cancel Connection: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, pretty_exception("Cancellation Error:", e),
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
      Snackbar.show(ABC.c, "Refreshing Data: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, pretty_exception("Refreshing Data Error:", e),
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
      Snackbar.show(ABC.c, "Displaying Data: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, pretty_exception("Displaying Data Error:", e),
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
        temp = loading();
        break;
    }
    return temp;
  }

  Widget loading() {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading Data...."),
            ],
          ),
        ),
      ),
    );
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
      return;
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
            Snackbar.show(ABC.c,
                "$characteristic_name Write to ${target_characteristic.uuid}: Success",
                success: true);
          }
          // Check if the characteristic supports write with response
          else if (target_characteristic.properties.write) {
            await target_characteristic.write(value.codeUnits,
                withoutResponse: false);
            Snackbar.show(ABC.c,
                "$characteristic_name Write to ${target_characteristic.uuid}: Success",
                success: true);
          }
          // Characteristic is not writable
          else {
            Snackbar.show(
              ABC.c,
              "$characteristic_name Write to ${target_characteristic.uuid}: Characteristic not writable",
              success: false,
            );
          }
        } catch (e) {
          Snackbar.show(
            ABC.c,
            "$characteristic_name Write to ${target_characteristic.uuid}: Error - $e",
            success: false,
          );
        }
      }
    } else {
      Snackbar.show(
        ABC.c,
        "$characteristic_name Write: Characteristics not found",
        success: false,
      );
    }
  }

  Map<String, List<String>> drop_down_items = {
    "Algox_Cell_Nos": ["2", "4", "6", "8", "10", "12", "14", "16"],
    "Battery_cell_nos": ["2", "4", "6", "8", "10", "12", "14", "16"]
  };

  final Map<String, double> slider_values = {
    "Algox_Current": 0.0,
    "Battery_capacity": 0.0,
    "Battery_constant_current": 0.0,
    "Battery_peak_current": 0.0,
    "Battery_max_voltage": 0.0,
    "Battery_min_voltage": 0.0,
    "Battery_operating_temperature": 0.0,
    "SOC": 0.0
  };

  Map<String, List<double>> slider_min_max = {
    "Algox_Current": [0.0, 100.0],
    "Battery_capacity": [0.0, 100.0],
    "Battery_constant_current": [0.0, 180.0],
    "Battery_peak_current": [0.0, 180.0],
    "Battery_max_voltage": [0.0, 4350.0],
    "Battery_min_voltage": [0.0, 2500.0],
    "Battery_operating_temperature": [0.0, 80.0],
    "SOC": [0.0, 100.0]
  };

  Map<String, int> slider_divisions = {
    "Algox_Current": 20,
    "Battery_capacity": 100,
    "Battery_constant_current": 90,
    "Battery_peak_current": 90,
    "Battery_max_voltage": 87,
    "Battery_min_voltage": 50,
    "Battery_operating_temperature": 80,
    "SOC": 100
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_drop_down_for_characteristic(
                      "Battery_cell_nos", "Number of Battery Cells"),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_text_field_for_characteristic(
                      "Battery_id*", "Battery ID",
                      is_required: true, max: 65535, min: 1),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_text_field_for_characteristic(
                      "BMS_id*", "BMS ID",
                      is_required: true, max: 65535, min: 1),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_text_field_for_characteristic(
                      "Battery_capacity", "Battery Capacity (in mAh)",
                      max: 65535, min: 1000),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_text_field_for_characteristic(
                      "Battery_constant_current",
                      "Battery Constant Current (in Amps)",
                      max: 150,
                      min: 0),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_text_field_for_characteristic(
                      "Battery_peak_current", "Battery Peak Current (in Amps)",
                      max: 180, min: 0),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_text_field_for_characteristic(
                      "Battery_max_voltage", "Cell Maximum Voltage (in mVolts)",
                      max: 4400, min: 0),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_text_field_for_characteristic(
                      "Battery_min_voltage", "Cell Minimum Voltage (in mVolts)",
                      max: 2500, min: 0),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_text_field_for_characteristic(
                      "Battery_operating_temperature",
                      "Battery Operating Temperature (in °C)",
                      max: 80,
                      min: 0),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_toggle_for_characteristic(
                      "Battery_DSG_C", "Protection Enabling Flags"),
                ),
                if (toggle_values["Battery_DSG_C"] == true)
                  ExpansionTile(
                    title: Text('Protections to be enabled'),
                    initiallyExpanded: false,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: build_toggle_for_characteristic(
                            "DSG_OverCurrent", "Discharge OverCurrent"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: build_toggle_for_characteristic(
                            "CHG_OverCurrent", "Charge OverCurrent"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: build_toggle_for_characteristic(
                            "CHG_OverVoltage", "Charge OverVoltage"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: build_toggle_for_characteristic(
                            "DSG_OverTemperature", "Discharge OverTemperature"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: build_toggle_for_characteristic(
                            "CHG_OverTemperature", "Charge OverTemperature"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: build_toggle_for_characteristic(
                            "DSG_UnderVoltage", "Discharge UnderVoltage"),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: build_toggle_for_characteristic(
                      "Battery_CHG_C", "Self Discharge Feature"),
                ),
                if (toggle_values["Battery_CHG_C"] == true)
                  ExpansionTile(
                    title: Text('Range of SOC'),
                    initiallyExpanded: false,
                    children: [
                      SizedBox(height: size.height * 0.01),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: build_text_field_for_characteristic(
                            "SOC", "State of Charge",
                            max: 100, min: 0),
                      ),
                    ],
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.mainColor_1,
                ),
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
            ),
          ],
        ),
      ),
    );
  }

  final AlgoX_form_key = GlobalKey<FormState>();
  List<String> characteristics = [
    "Charging_type",
    "Cell_Chemistry",
    "Algox_Cell_Nos",
    "Algox_Current",
    "Start_Charging"
  ];

  final Map<String, String> defaultValues = {
    "Charging_type": "1", // Balance Charge
    "Cell_Chemistry": "0", // LiPo
    "Algox_Cell_Nos": "6",
    "Algox_Current": "20.0",
    "Start_Charging": "0", // Off
  };

  Widget buildChargingTypeDropdown() {
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
                value: _getChargingTypeValue() ??
                    _getChargingTypeLabel(defaultValues["Charging_type"]),
                onChanged: (new_value) {
                  setState(() {
                    String mappedValue = '';
                    switch (new_value) {
                      case "Fast Charge":
                        mappedValue = '0';
                        break;
                      case "Balance Charge":
                        mappedValue = '1';
                        break;
                      case "Storage Charge":
                        mappedValue = '2';
                        break;
                    }
                    BMS_write_controller["Charging_type"]?.text = mappedValue;
                  });
                },
                items: ["Fast Charge", "Balance Charge", "Storage Charge"]
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: "Charging Type",
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                iconEnabledColor: Colors.white,
                dropdownColor: CustomColors.mainColor_3,
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select Charging Type';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCellChemistryDropdown() {
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
                value: _getCellChemistryValue() ??
                    _getCellChemistryLabel(defaultValues["Cell_Chemistry"]),
                onChanged: (new_value) {
                  setState(() {
                    String mappedValue = '';
                    switch (new_value) {
                      case "LiPo":
                        mappedValue = '0';
                        break;
                      case "LiIon":
                        mappedValue = '1';
                        break;
                      case "LiHv":
                        mappedValue = '2';
                        break;
                      case "Graphene":
                        mappedValue = '3';
                        break;
                    }
                    BMS_write_controller["Cell_Chemistry"]?.text = mappedValue;
                  });
                },
                items:
                    ["LiPo", "LiIon", "LiHv", "Graphene"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: "Cell Chemistry",
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                iconEnabledColor: Colors.white,
                dropdownColor: CustomColors.mainColor_3,
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select Cell Chemistry';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getChargingTypeValue() {
    final textValue = BMS_write_controller["Charging_type"]?.text;
    switch (textValue) {
      case '0':
        return "Fast Charge";
      case '1':
        return "Balance Charge";
      case '2':
        return "Storage Charge";
      default:
        return null;
    }
  }

  String? _getCellChemistryValue() {
    final textValue = BMS_write_controller["Cell_Chemistry"]?.text;
    switch (textValue) {
      case '0':
        return "LiPo";
      case '1':
        return "LiIon";
      case '2':
        return "LiHv";
      case '3':
        return "Graphene";
      default:
        return null;
    }
  }

  String _getChargingTypeLabel(String? value) {
    switch (value) {
      case '0':
        return 'Fast Charge';
      case '1':
        return 'Balance Charge';
      case '2':
        return 'Storage Charge';
      default:
        return 'Not Set';
    }
  }

  String _getCellChemistryLabel(String? value) {
    switch (value) {
      case '0':
        return 'LiPo';
      case '1':
        return 'LiIon';
      case '2':
        return 'LiHv';
      case '3':
        return 'Graphene';
      default:
        return 'Not Set';
    }
  }

  void showAlgoXConfigDialog() {
    // Initialize controllers with default values if they're empty
    for (var characteristic in characteristics) {
      if (BMS_write_controller[characteristic]?.text.isEmpty ?? true) {
        BMS_write_controller[characteristic]?.text =
            defaultValues[characteristic]!;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("AlgoX Controls"),
              content: Form(
                key: AlgoX_form_key,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentStep < characteristics.length - 1)
                        _buildStepContent(characteristics[currentStep])
                      else
                        _buildSummaryContent(),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (currentStep > 0)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentStep--;
                                });
                              },
                              child: Text(
                                "Back",
                                style:
                                    TextStyle(color: CustomColors.mainColor_1),
                              ),
                            ),
                          if (currentStep == 0)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                "Back",
                                style:
                                    TextStyle(color: CustomColors.mainColor_1),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: () {
                              if (currentStep < characteristics.length - 1) {
                                if (AlgoX_form_key.currentState!.validate()) {
                                  try {
                                    _sendCharacteristicValue(
                                        characteristics[currentStep]);
                                    if (currentStep <
                                        characteristics.length - 1) {
                                      setState(() {
                                        currentStep++;
                                      });
                                    }
                                  } catch (e) {
                                    print("Error occurred: $e");
                                  }
                                }
                              } else {
                                // On the last step, show summary and perform final actions
                                if (AlgoX_form_key.currentState!.validate()) {
                                  try {
                                    _sendCharacteristicValue(
                                        characteristics[currentStep]);
                                    Navigator.of(context).pop();
                                    // AlgoX_on_send_all_pressed();
                                  } catch (e) {
                                    print("Error occurred: $e");
                                  }
                                }
                              }
                            },
                            child: Text(
                              currentStep == characteristics.length - 1
                                  ? "Finish"
                                  : "Next",
                              style: TextStyle(color: CustomColors.mainColor_1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Summary",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        SizedBox(height: 10),
        for (var characteristic in characteristics)
          if (characteristic != "Start_Charging")
            Text(
              '${_formatCharacteristicName(characteristic)}: ${_getSummaryValue(characteristic)}',
              style: TextStyle(color: Colors.black),
            ),
        SizedBox(height: 10),
        buildStartChargingWidget(),
      ],
    );
  }

  String _getSummaryValue(String characteristic) {
    switch (characteristic) {
      case "Charging_type":
        return _getChargingTypeLabel(
            BMS_write_controller[characteristic]?.text);
      case "Cell_Chemistry":
        return _getCellChemistryLabel(
            BMS_write_controller[characteristic]?.text);
      default:
        return BMS_write_controller[characteristic]?.text ?? 'Not Set';
    }
  }

  String _formatCharacteristicName(String characteristic) {
    return characteristic
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  bool _isOn = false;

  Widget buildStartChargingWidget() {
    final Size size = MediaQuery.of(context).size;

    return StatefulBuilder(
      builder: (context, setState) {
        _isOn = BMS_write_controller["Start_Charging"]?.text == '1';
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.height * 0.01),
            color: Colors.greenAccent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: size.width * 0.01),
              Text("OFF: "),
              Switch(
                value: _isOn,
                onChanged: (bool value) {
                  setState(() {
                    _isOn = value;
                    BMS_write_controller["Start_Charging"]?.text =
                        value ? '1' : '0';
                  });
                  _sendPowerState(value);
                },
              ),
              Text(" :ON"),
              SizedBox(width: size.width * 0.01),
            ],
          ),
        );
      },
    );
  }

  void _sendCharacteristicValue(String characteristic) async {
    String value = '';

    switch (characteristic) {
      case "Algox_Cell_Nos":
      case "Algox_Current":
      case "Charging_type":
      case "Cell_Chemistry":
      case "Start_Charging":
        value = BMS_write_controller[characteristic]?.text ??
            defaultValues[characteristic]!;
        break;
      default:
        print("Unknown characteristic: $characteristic");
        return;
    }

    // Ensure value is not empty
    if (value.isEmpty) {
      value = defaultValues[characteristic]!;
    }

    // Update the controller with the value (default or user-defined)
    BMS_write_controller[characteristic]?.text = value;

    // Call the on_write_pressed function
    await on_write_pressed(characteristic);

    print("Sent value '$value' for $characteristic");
  }

  Widget _buildStepContent(String characteristic) {
    switch (characteristic) {
      case "Algox_Cell_Nos":
        return build_drop_down_for_characteristic(
            characteristic, "Algox Cell Nos");
      case "Algox_Current":
        return build_text_field_for_characteristic(
            characteristic, "AlgoX Current");
      case "Charging_type":
        return buildChargingTypeDropdown();
      case "Cell_Chemistry":
        return buildCellChemistryDropdown();
      case "Start_Charging":
        return build_toggle_for_characteristic(
            characteristic, "Start Charging");
      default:
        return Container();
    }
  }

  Widget build_text_field_for_characteristic(String key, String label,
      {bool is_required = false, double? min, double? max}) {
    final Size size = MediaQuery.of(context).size;
    bool isCompulsory = key.endsWith('*');
    String displayKey = isCompulsory ? key.substring(0, key.length - 1) : key;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        Color labelColor = Colors.white;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.height * 0.01),
            color: CustomColors.mainColor_3,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  controller: BMS_write_controller[displayKey],
                  decoration: InputDecoration(
                      labelText: isCompulsory ? "$label *" : label,
                      labelStyle: TextStyle(color: labelColor),
                      border: InputBorder.none,
                      errorStyle: TextStyle(color: Colors.amber)),
                  onChanged: (value) {
                    setState(() {
                      if (value.isNotEmpty) {
                        double? numValue = double.tryParse(value);
                        if (numValue != null) {
                          if ((min != null && numValue < min) ||
                              (max != null && numValue > max)) {
                            labelColor = Colors.black;
                          } else {
                            labelColor = Colors.white;
                          }
                        } else {
                          labelColor = Colors.black;
                        }
                      } else {
                        labelColor = Colors.white;
                      }
                    });
                  },
                  validator: (value) {
                    if (isCompulsory && (value == null || value.isEmpty)) {
                      return 'Please enter $label';
                    }
                    if (value != null && value.isNotEmpty) {
                      double? numValue = double.tryParse(value);
                      if (numValue == null) {
                        return 'Please enter a valid number';
                      }
                      if (min != null && numValue < min) {
                        return 'Value must be at least $min';
                      }
                      if (max != null && numValue > max) {
                        return 'Value must be at most $max';
                      }
                    }
                    return null;
                  },
                ),
                if (min != null || max != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Valid range: ${min ?? 'No min'} - ${max ?? 'No max'}',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget build_drop_down_for_characteristic(String key, String label) {
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
                  labelText: label,
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                iconEnabledColor: Colors.white,
                dropdownColor: CustomColors.mainColor_3,
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select $label';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build_slider_for_characteristic(String key) {
    final Size size = MediaQuery.of(context).size;

    // Convert the key to a user-friendly label
    String formattedKey = key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

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
                    '$formattedKey: ${slider_values[key]?.toStringAsFixed(1)}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            double new_value = (slider_values[key] ?? 0) - 1;
                            if (new_value >= (slider_min_max[key]?[0] ?? 0)) {
                              slider_values[key] = new_value;
                              BMS_write_controller[key]?.text =
                                  new_value.toStringAsFixed(1);
                            }
                          });
                        },
                      ),
                      Spacer(),
                      Container(
                        width: size.width * 0.4,
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
                            double new_value = (slider_values[key] ?? 0) + 1;
                            if (new_value <= (slider_min_max[key]?[1] ?? 100)) {
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
          ],
        ),
      ),
    );
  }

  Widget build_toggle_for_characteristic(String key, String label) {
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
                    label,
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

      print('Processing characteristic: $characteristic_name');
      print('Characteristic UUID: $characteristic_uuid');
      print('Value: $value');

      if (value.isEmpty || characteristic_uuid == null) {
        summary_message +=
            '$characteristic_name Write: No value provided or invalid UUID\n';
        all_success = false;
        continue;
      }

      if (BMS_last_sent_values[characteristic_name] == value) {
        summary_message +=
            '$characteristic_name Write: Value unchanged, not sending\n';
        continue;
      }

      BluetoothCharacteristic? target_characteristic;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          print('Checking characteristic UUID: ${characteristic.uuid}');
          if (characteristic.uuid.toString() == characteristic_uuid) {
            target_characteristic = characteristic;
            break;
          }
        }
        if (target_characteristic != null) break;
      }

      if (target_characteristic != null) {
        try {
          print('Writing value to characteristic: $characteristic_name');
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

    print(summary_message); // Print the summary message for debugging
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
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: size.height * 0.075,
            decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.all(Radius.circular(10))),
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
                              width: size.width * 0.025,
                            ),
                            Icon(Icons.power_off),
                            SizedBox(
                              width: size.width * 0.025,
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
          ),
        );

      case 4: // Charging Mode
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: size.height * 0.075,
            decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.all(Radius.circular(10))),
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
          ),
        );

      case 3: // Discharging Mode
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: size.height * 0.075,
            decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(10))),
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
          ),
        );
      default:
        return SizedBox.shrink();
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
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: size.height * 0.075,
            decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.all(Radius.circular(10))),
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
                              width: size.width * 0.025,
                            ),
                            Icon(Icons.power_off),
                            SizedBox(
                              width: size.width * 0.025,
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
          ),
        );

      case 2: // Charging Mode
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: size.height * 0.075,
            decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.all(Radius.circular(10))),
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
          ),
        );

      default:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: size.height * 0.075,
            decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.all(Radius.circular(10))),
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
                              width: size.width * 0.025,
                            ),
                            Icon(Icons.power_off),
                            SizedBox(
                              width: size.width * 0.025,
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
          ),
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

  String _getBMSFaultStatus(int faultValue) {
    switch (faultValue) {
      case 1:
        return 'Over Voltage Error';
      case 2:
        return 'Under Voltage Error';
      case 4:
        return 'Over Temperature Error';
      case 3:
        return 'Over Current Error';
      case 5:
        return 'Cell Disbalance';
      default:
        return 'Fault Detected';
    }
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

    String hexValue =
        batteryHealthStatus.round().toRadixString(16).padLeft(4, '0');
    int stateOfHealth = int.parse(hexValue.substring(0, 2), radix: 16);
    int stateOfCharge = int.parse(hexValue.substring(2, 4), radix: 16);

    // double _stateOfCharge = stateOfCharge / 100;
    // double _stateOfHealth = stateOfHealth / 100;

    // int stateOfCharge = (batteryHealthStatus / 100).floor();
    // int stateOfHealth = (batteryHealthStatus % 100).round();

    // double _stateOfCharge = stateOfCharge / 100;
    // double _stateOfHealth = stateOfHealth / 100;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
        child: Container(
          color: CustomColors.mainColor_1,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Battery Temperature',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        // Calculate temperature based on the condition
                        batteryTemperature > 12000
                            ? ((65535 - batteryTemperature) * -0.01)
                                    .toStringAsFixed(2) +
                                ' °C'
                            : (batteryTemperature * 0.01).toStringAsFixed(2) +
                                ' °C',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Container(
              //     decoration: BoxDecoration(
              //         gradient: LinearGradient(
              //             begin: Alignment.centerLeft,
              //             end: Alignment.centerRight,
              //             colors: [
              //               CustomColors.mainColor_3,
              //               CustomColors.mainColor_3,
              //               CustomColors.mainColor_3,
              //               CustomColors.mainColor_3,
              //               CustomColors.mainColor_2,
              //               CustomColors.mainColor_2
              //             ]),
              //         borderRadius: BorderRadius.circular(size.height * 0.01),
              //         color: CustomColors.mainColor_3),
              //     child: ListTile(
              //       title: const Text(
              //         'Battery Health Status',
              //         style: TextStyle(
              //             fontWeight: FontWeight.bold, color: Colors.white),
              //       ),
              //       trailing: Text(
              //           hexValue,
              //           style: TextStyle(
              //               fontWeight: FontWeight.bold,
              //               color: Colors.white,
              //               fontSize: size.height * 0.018)),
              //     ),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Battery Cycle Count',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (batteryCycleCount * 1).toStringAsFixed(0) + ' ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              if (bmsFault != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'BMS Fault',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(_getBMSFaultStatus(bmsFault.toInt()),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (BMS_read_write_selector == 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: CustomColors.mainColor_1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: size.height * 0.2,
                          width: size.width * 0.45,
                          child: Card(
                            margin: EdgeInsets.all(size.height * 0.01),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    "State of Charge",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: size.height * 0.02),
                                  ),
                                  Spacer(),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                        begin: 0, end: (stateOfCharge * 0.01)),
                                    duration: Duration(seconds: 2),
                                    builder: (context, value, child) {
                                      Color color;
                                      if (value < 0.25) {
                                        color = Colors.red;
                                      } else if (value >= 0.25 &&
                                          value <= 0.75) {
                                        color = Colors.amber;
                                      } else {
                                        color = Colors.green;
                                      }
                                      return CircularPercentIndicator(
                                        radius: size.height * 0.05,
                                        percent: value,
                                        lineWidth: 10,
                                        progressColor: color,
                                        center: Text(
                                          (value * 100).toStringAsFixed(1) +
                                              '%',
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.2,
                          width: size.width * 0.45,
                          child: Card(
                            margin: EdgeInsets.all(size.height * 0.01),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('State of Health',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: size.height * 0.02)),
                                  Spacer(),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                        begin: 0, end: (stateOfHealth * 0.01)),
                                    duration: Duration(seconds: 2),
                                    builder: (context, value, child) {
                                      Color color;
                                      if (value < 0.25) {
                                        color = Colors.red;
                                      } else if (value >= 0.25 &&
                                          value <= 0.75) {
                                        color = Colors.amber;
                                      } else {
                                        color = Colors.green;
                                      }
                                      return CircularPercentIndicator(
                                        radius: size.height * 0.05,
                                        percent: value,
                                        lineWidth: 10,
                                        progressColor: color,
                                        center: Text(
                                          (value * 100).toStringAsFixed(1) +
                                              '%',
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
        child: Container(
          color: CustomColors.mainColor_1,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
            ],
          ),
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

    double batteryTemperature = data_fetched["Battery_temperature"] != null
        ? double.parse(data_fetched["Battery_temperature"]!)
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
        child: Container(
          color: CustomColors.mainColor_1,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell1 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell1Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell2 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell2Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell3 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell3Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell4 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell4Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell5 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell5Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell6 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell6Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell7 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell7Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell8 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell8Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell9 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell9Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
            ],
          ),
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

    // double batteryHealthStatus = data_fetched["Battery_health_status"] != null
    //     ? double.parse(data_fetched["Battery_health_status"]!)
    //     : 0.0;

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

    // String hexValue =
    //     batteryHealthStatus.round().toRadixString(16).padLeft(4, '0');
    // int stateOfHealth = int.parse(hexValue.substring(0, 2), radix: 16);
    // int stateOfCharge = int.parse(hexValue.substring(2, 4), radix: 16);

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
        child: Container(
          color: CustomColors.mainColor_1,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Container(
              //     decoration: BoxDecoration(
              //         gradient: LinearGradient(
              //             begin: Alignment.centerLeft,
              //             end: Alignment.centerRight,
              //             colors: [
              //               CustomColors.mainColor_3,
              //               CustomColors.mainColor_3,
              //               CustomColors.mainColor_3,
              //               CustomColors.mainColor_3,
              //               CustomColors.mainColor_2,
              //               CustomColors.mainColor_2
              //             ]),
              //         borderRadius: BorderRadius.circular(size.height * 0.01),
              //         color: CustomColors.mainColor_3),
              //     child: ListTile(
              //       title: const Text(
              //         'Battery Health Status',
              //         style: TextStyle(
              //             fontWeight: FontWeight.bold, color: Colors.white),
              //       ),
              //       trailing: Text(
              //           (batteryHealthStatus * 0.001).toStringAsFixed(2) + ' %',
              //           style: TextStyle(
              //               fontWeight: FontWeight.bold,
              //               color: Colors.white,
              //               fontSize: size.height * 0.018)),
              //     ),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Package Remaining Capacity',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (packageRemainingCapacity * 1).toStringAsFixed(0) +
                            ' mAh',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell1 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell1Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell2 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell2Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell3 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell3Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell4 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell4Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell5 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell5Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell6 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell6Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell7 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell7Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell8 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell8Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Cell9 Voltage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (cell9Voltage * 0.001).toStringAsFixed(3) + ' V',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
            ],
          ),
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

    String hexValue =
        batteryHealthStatus.round().toRadixString(16).padLeft(4, '0');
    int stateOfHealth = int.parse(hexValue.substring(0, 2), radix: 16);
    int stateOfCharge = int.parse(hexValue.substring(2, 4), radix: 16);

    // int stateOfCharge = (batteryHealthStatus / 100).floor();
    // int stateOfHealth = (batteryHealthStatus % 100).round();

    // double _stateOfCharge = stateOfCharge / 100;
    // double _stateOfHealth = stateOfHealth / 100;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
        child: Container(
          color: CustomColors.mainColor_1,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              if (BMS_read_write_selector == 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: CustomColors.mainColor_1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: size.height * 0.2,
                          width: size.width * 0.45,
                          child: Card(
                            margin: EdgeInsets.all(size.height * 0.01),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    "State of Charge",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: size.height * 0.02),
                                  ),
                                  Spacer(),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                        begin: 0, end: (stateOfCharge * 0.01)),
                                    duration: Duration(seconds: 2),
                                    builder: (context, value, child) {
                                      Color color;
                                      if (value < 0.25) {
                                        color = Colors.red;
                                      } else if (value >= 0.25 &&
                                          value <= 0.75) {
                                        color = Colors.amber;
                                      } else {
                                        color = Colors.green;
                                      }
                                      return CircularPercentIndicator(
                                        radius: size.height * 0.05,
                                        percent: value,
                                        lineWidth: 10,
                                        progressColor: color,
                                        center: Text(
                                          (value * 100).toStringAsFixed(1) +
                                              '%',
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.2,
                          width: size.width * 0.45,
                          child: Card(
                            margin: EdgeInsets.all(size.height * 0.01),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('State of Health',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: size.height * 0.02)),
                                  Spacer(),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                        begin: 0, end: (stateOfHealth * 0.01)),
                                    duration: Duration(seconds: 2),
                                    builder: (context, value, child) {
                                      Color color;
                                      if (value < 0.25) {
                                        color = Colors.red;
                                      } else if (value >= 0.25 &&
                                          value <= 0.75) {
                                        color = Colors.amber;
                                      } else {
                                        color = Colors.green;
                                      }
                                      return CircularPercentIndicator(
                                        radius: size.height * 0.05,
                                        percent: value,
                                        lineWidth: 10,
                                        progressColor: color,
                                        center: Text(
                                          (value * 100).toStringAsFixed(1) +
                                              '%',
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Package Remaining Capacity',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (packageRemainingCapacity * 1).toStringAsFixed(0) +
                            ' mAh',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              if (cell1Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell1 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell1Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell2Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell2 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell2Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell3Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell3 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell3Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell4Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell4 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell4Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell5Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell5 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell5Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell6Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell6 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell6Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell7Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell7 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell7Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell8Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell8 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell8Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell9Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'Cell9 Voltage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(
                          (cell9Voltage * 0.001).toStringAsFixed(3) + ' V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
              if (cell10Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
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
                ),
              if (cell11Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
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
                ),
              if (cell12Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
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
                ),
              if (cell13Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
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
                ),
              if (cell14Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
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
                ),
              if (cell15Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
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
                ),
              if (cell16Voltage != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
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
                ),
              if (bmsFault != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'BMS Fault',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(_getBMSFaultStatus(bmsFault.toInt()),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
            ],
          ),
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

    String hexValue =
        batteryHealthStatus.round().toRadixString(16).padLeft(4, '0');
    int stateOfHealth = int.parse(hexValue.substring(0, 2), radix: 16);
    int stateOfCharge = int.parse(hexValue.substring(2, 4), radix: 16);

    // int stateOfCharge = (batteryHealthStatus / 100).floor();
    // int stateOfHealth = (batteryHealthStatus % 100).round();

    // double _stateOfCharge = stateOfCharge / 100;
    // double _stateOfHealth = stateOfHealth / 100;

    Future<void> refresh_data() async {
      setState(() {
        on_refresh_pressed();
      });
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: refresh_data,
        child: Container(
          decoration: BoxDecoration(
              color: CustomColors.mainColor_1,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10))),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              if (BMS_read_write_selector == 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: CustomColors.mainColor_1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: size.height * 0.2,
                          width: size.width * 0.45,
                          child: Card(
                            margin: EdgeInsets.all(size.height * 0.01),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    "State of Charge",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: size.height * 0.02),
                                  ),
                                  Spacer(),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                        begin: 0, end: (stateOfCharge * 0.01)),
                                    duration: Duration(seconds: 2),
                                    builder: (context, value, child) {
                                      Color color;
                                      if (value < 0.25) {
                                        color = Colors.red;
                                      } else if (value >= 0.25 &&
                                          value <= 0.75) {
                                        color = Colors.amber;
                                      } else {
                                        color = Colors.green;
                                      }
                                      return CircularPercentIndicator(
                                        radius: size.height * 0.05,
                                        percent: value,
                                        lineWidth: 10,
                                        progressColor: color,
                                        center: Text(
                                          (value * 100).toStringAsFixed(1) +
                                              '%',
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.2,
                          width: size.width * 0.45,
                          child: Card(
                            margin: EdgeInsets.all(size.height * 0.01),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('State of Health',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: size.height * 0.02)),
                                  Spacer(),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                        begin: 0, end: (stateOfHealth * 0.01)),
                                    duration: Duration(seconds: 2),
                                    builder: (context, value, child) {
                                      Color color;
                                      if (value < 0.25) {
                                        color = Colors.red;
                                      } else if (value >= 0.25 &&
                                          value <= 0.75) {
                                        color = Colors.amber;
                                      } else {
                                        color = Colors.green;
                                      }
                                      return CircularPercentIndicator(
                                        radius: size.height * 0.05,
                                        percent: value,
                                        lineWidth: 10,
                                        progressColor: color,
                                        center: Text(
                                          (value * 100).toStringAsFixed(1) +
                                              '%',
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
                      borderRadius: BorderRadius.circular(size.height * 0.01),
                      color: CustomColors.mainColor_3),
                  child: ListTile(
                    title: const Text(
                      'Package Remaining Capacity',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    trailing: Text(
                        (packageRemainingCapacity * 1).toStringAsFixed(0) +
                            ' mAh',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: size.height * 0.018)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_3,
                            CustomColors.mainColor_2,
                            CustomColors.mainColor_2
                          ]),
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
              ),
              if (bmsFault != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_3,
                              CustomColors.mainColor_2,
                              CustomColors.mainColor_2
                            ]),
                        borderRadius: BorderRadius.circular(size.height * 0.01),
                        color: CustomColors.mainColor_3),
                    child: ListTile(
                      title: const Text(
                        'BMS Fault',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Text(_getBMSFaultStatus(bmsFault.toInt()),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: size.height * 0.018)),
                    ),
                  ),
                ),
            ],
          ),
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
        toolbarHeight: size.height * 0.075,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: size.height * 0.1,
                color: Colors.white,
                child: Center(child: BMS_state_show()),
                alignment: Alignment.topCenter,
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade500],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          read_write_screens[BMS_read_write_selector],
        ],
      ),
      // bottomNavigationBar: Padding(
      //   padding: const EdgeInsets.all(8.0),
      //   child: BMS_navigation_bar(),
      // ),
    );
  }

  Widget AlgoX_display() {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.white,
        toolbarHeight: size.height * 0.075,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: size.height * 0.1,
                color: Colors.white,
                alignment: Alignment.topCenter,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: size.height * 0.075,
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
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
                  ),
                ),
              )
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade500],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AlgoX_charging_widget()
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAlgoXConfigDialog();
        },
        label: Text(
          "Charger Control",
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  Future<void> _sendPowerState(bool isOn) async {
    final String characteristicUuid = '9027cc8b-da21-4c8a-95c2-44fc448834f4';
    final String value = isOn ? '1' : '0';
    String summaryMessage = '';

    BluetoothCharacteristic? targetCharacteristic;

    for (var service in services) {
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
          summaryMessage = 'Power ${isOn ? 'ON' : 'OFF'} Write: Success';
        } else if (targetCharacteristic.properties.write) {
          await targetCharacteristic.write(value.codeUnits,
              withoutResponse: false);
          summaryMessage = 'Power ${isOn ? 'ON' : 'OFF'} Write: Success';
        } else {
          summaryMessage = 'Power Write: Characteristic not writable';
        }
      } catch (e) {
        summaryMessage = 'Power Write: Error - $e';
      }
    } else {
      summaryMessage = 'Power Write: Characteristic not found';
    }

    Snackbar.show(ABC.c, summaryMessage,
        success: summaryMessage.contains('Success'));
  }

  Widget AlgoPAD_display() {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.white,
        toolbarHeight: size.height * 0.075,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: size.height * 0.1,
                color: Colors.white,
                child: Center(child: AlgoPAD_state_show()),
                alignment: Alignment.topCenter,
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade500],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AlgoPAD_state_display()
        ],
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

    if (product_state == 10101) {
      temp = BMS_display();
    } else if (product_state == 20101) {
      temp = AlgoX_display();
    } else if (product_state == 30101) {
      temp = AlgoPAD_display();
    }

    return temp;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(key: Snackbar.snackBarKeyC, child: build_body());
  }
}
