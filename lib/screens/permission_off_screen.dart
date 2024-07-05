import 'dart:async';
import 'dart:io';

import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

// ignore: must_be_immutable
class BluetoothOffScreen extends StatelessWidget {
  BluetoothOffScreen({super.key, this.adapterState});

  final BluetoothAdapterState? adapterState;
  

  Widget buildBluetoothOffIcon(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: size.height * 0.125,child: Lottie.asset("assets/gifs/bluetooth.json")),
        SizedBox(height: size.height * 0.15,child: Lottie.asset("assets/gifs/location.json")),
      ],
    );
  }

  Location location = Location();

  Future<void> _toggleLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled){
      serviceEnabled = await location.requestService();
      if (!serviceEnabled){
        return;
      }
    }

    var permissionGranted = await location.serviceEnabled();

    if (permissionGranted == Permission.location.status.isDenied){
      permissionGranted = (await location.requestPermission()) as bool;
      if (permissionGranted != Permission.location.status.isGranted){
        return;
      }
    }
  }

  Widget buildTitle(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    String? state = adapterState?.toString().split(".").last;
    return Text(
      //
      'Enable Bluetooth and Location',
      style: Theme.of(context).primaryTextTheme.titleSmall?.copyWith(color: Colors.black,fontSize: size.height*0.025),
    );
  }

  Widget buildTurnOnButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomColors.mainColor_1
        ),
        child: const Text('Enable and Proceed',style: TextStyle(color: Colors.white),),
        onPressed: () async {
          try {
            if (Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
              _toggleLocation();
            }
          } catch (e) {
            Snackbar.show(ABC.a, prettyException("Error Turning On:", e), success: false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyA,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade500],begin: Alignment.topCenter,end: Alignment.bottomCenter)
            ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                buildBluetoothOffIcon(context),
                buildTitle(context),
                if (Platform.isAndroid) buildTurnOnButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
