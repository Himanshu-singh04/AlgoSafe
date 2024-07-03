import 'dart:io';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

Location location = Location();

Future<void> toggleLocation() async {
  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return;
    }
  }
  var permissionGranted = await location.serviceEnabled();
  if (permissionGranted == Permission.location.status.isDenied) {
    permissionGranted = (await location.requestPermission()) as bool;
    if (permissionGranted != Permission.location.status.isGranted) {
      return;
    }
  }
}

Future<void> toggleBLE() async {
  try {
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  } catch (e) {
    Snackbar.show(ABC.a, prettyException("Error Turning On:", e),
        success: false);
  }
}
