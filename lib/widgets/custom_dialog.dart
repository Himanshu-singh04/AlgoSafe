import 'dart:io';

import 'package:algo_safe/main.dart';
import 'package:algo_safe/utils/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

void showCustomDialog(BuildContext context, {required ValueChanged onValue}) {
  final Size size = MediaQuery.of(context).size;
  bool checkBox = false;

  showGeneralDialog(
    context: context,
    barrierLabel: "Barrier",
    barrierDismissible: true,
    // barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) {
      return Center(
        child: Container(
          width: size.width ,
          height: size.height * 0.25,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 30),
                blurRadius: 60,
              ),
              const BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 30),
                blurRadius: 60,
              ),
            ],
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: size.width * 0.2,
                              color: Colors.black,
                            ),
                            Icon(
                              Icons.location_off,
                              size: size.width * 0.2,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        ElevatedButton(
                            onPressed: () async {
                              try {
                                if (Platform.isAndroid) {
                                  await FlutterBluePlus.turnOn();
                                }
                              } catch (e) {
                                Snackbar.show(ABC.a,
                                    prettyException("Error Turning On:", e),
                                    success: false);
                              }

                              Location location = Location();
                              bool serviceEnabled =
                                  await location.serviceEnabled();
                              if (!serviceEnabled) {
                                serviceEnabled =
                                    await location.requestService();
                                if (!serviceEnabled) {
                                  return;
                                }
                              }

                              var permissionGranted =
                                  await location.serviceEnabled();

                              if (permissionGranted ==
                                  Permission.location.status.isDenied) {
                                permissionGranted = (await location
                                    .requestPermission()) as bool;
                                if (permissionGranted !=
                                    Permission.location.status.isGranted) {
                                  return;
                                }
                              }
                              Navigator.of(context)
                                  .pushReplacement(_createRoute());
                            },
                            child: Row(
                              children: [
                                Checkbox(value: checkBox, onChanged: (bool? value){checkBox = value!;}),
                                Text("Enable Permissions and Proceed"),
                              ],
                            )),

                            

                        // CheckboxListTile(
                        //   title: Text("title text"),
                        //   value: checkedValue,
                        //   onChanged: (newValue) {},
                        //   controlAffinity: ListTileControlAffinity
                        //       .leading, //  <-- leading Checkbox
                        // )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      Tween<Offset> tween;
      // if (anim.status == AnimationStatus.reverse) {
      //   tween = Tween(begin: const Offset(0, 1), end: Offset.zero);
      // } else {
      //   tween = Tween(begin: const Offset(0, -1), end: Offset.zero);
      // }

      tween = Tween(begin: const Offset(0, -1), end: Offset.zero);

      return SlideTransition(
        position: tween.animate(
          CurvedAnimation(parent: anim, curve: Curves.easeInOut),
        ),
        // child: FadeTransition(
        //   opacity: anim,
        //   child: child,
        // ),
        child: child,
      );
    },
  ).then(onValue);
}

Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const home_page(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
