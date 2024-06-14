import 'package:algosafe/controllers/ble_controller.dart';
import 'package:algosafe/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

class display_page extends StatefulWidget {
  final BluetoothDevice device;
  final bool isConnected;
  //const display_page({super.key});

  const display_page({
    Key? key,
    required this.device,
    required this.isConnected,
  }) : super(key: key);

  @override
  State<display_page> createState() => _display_pageState();
}

class _display_pageState extends State<display_page> {
  @override
  Widget build(BuildContext context) {

    final BleController bleController = Get.find();

    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.device.name)
          ,SizedBox(
            height: 8,
          ),
          Text(widget.device.id.id),
          SizedBox(
            height: 8,
          ),
          ElevatedButton(onPressed: (){
            bleController.disconnectToDevice(widget.device);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage(theme: ThemeData.light(),)));
          }, child: Text("disconnect"))
        ],),
      ),
    );
  }
}