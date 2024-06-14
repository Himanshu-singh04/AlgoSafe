import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController{

  FlutterBlue ble = FlutterBlue.instance;
  
// This Function will help users to scan near by BLE devices and get the list of Bluetooth devices.
  Future scanDevices() async{
    if(await Permission.bluetoothScan.request().isGranted){
      if(await Permission.bluetoothConnect.request().isGranted){
        ble.startScan(timeout: const Duration(seconds: 15));

        ble.stopScan();
      }
    }
  }

 Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();

   device.state.listen((isConnected) {
     if(isConnected == BluetoothDeviceState.connecting){
        print("${device.name}");
      }else if(isConnected == BluetoothDeviceState.connected){
        print("${device.name}");
      }else{
       print("Device Disconnected");
      }
    });

 }

 Future<void> disconnectToDevice(BluetoothDevice device) async {
  await device.disconnect();

  device.state.listen((isDisconnected){
    if (isDisconnected == BluetoothDeviceState.disconnecting){
      print("${device.name}");
    }
    else if(isDisconnected == BluetoothDeviceState.disconnected){
      print("device disconnected");
    }
  });
 }

  Stream<List<ScanResult>> get scanResults => ble.scanResults;

}