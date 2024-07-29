import 'dart:io';

import 'package:algo_safe/utils/colors.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';

// ignore: must_be_immutable
class BluetoothOffScreen extends StatelessWidget {
  BluetoothOffScreen({super.key, this.adapter_state});

  final BluetoothAdapterState? adapter_state;

  Widget build_bluetooth_off_icon(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
            height: size.height * 0.2,
            child: Lottie.asset("assets/gifs/bluetooth.json")),
      ],
    );
  }

  Location location = Location();

  Widget build_title(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Text(
      'Activate Bluetooth to connect',
      style: Theme.of(context)
          .primaryTextTheme
          .titleSmall
          ?.copyWith(color: Colors.black, fontSize: size.height * 0.025),
    );
  }

  Widget build_turn_on_button(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        style:
            ElevatedButton.styleFrom(backgroundColor: CustomColors.mainColor_3),
        child: const Text(
          'Enable and Proceed',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () async {
          try {
            if (Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
              // toggle_location();
            }
          } catch (e) {
            Snackbar.show(ABC.a, pretty_exception("Error Turning On:", e),
                success: false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyA,
      child: Container(
        width: size.width,
        height: size.height,
        child: Stack(children: [
          Stack(
            children: [
              Container(
                width: size.width,
                height: size.height * 0.875,
                decoration: BoxDecoration(color: CustomColors.mainColor_1),
              ),
              Container(
                width: size.width,
                height: size.height * 0.875,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.only(bottomRight: Radius.circular(70))),
                        child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                build_bluetooth_off_icon(context),
                SizedBox(
                  height: size.height * 0.025,
                ),
                build_title(context),
              ],
            ),
          ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: size.width,
              height: size.height * 0.1251,
              decoration: BoxDecoration(color: Colors.white),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: size.width,
              height: size.height * 0.1251,
              decoration: BoxDecoration(
                  color: CustomColors.mainColor_1,
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(70))),
                      child: build_turn_on_button(context),
            ),
          )
        ]),
      ),
    );
  }
}
