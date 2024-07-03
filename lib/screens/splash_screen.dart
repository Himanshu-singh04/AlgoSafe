import 'dart:async';
import 'dart:ui';
import 'package:algo_safe/main.dart';
import 'package:algo_safe/widgets/animated_button.dart';
import 'package:algo_safe/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rive/rive.dart';

// ignore: camel_case_types
class splash_screen extends StatefulWidget {
  splash_screen({super.key});

  @override
  State<splash_screen> createState() => _splash_screenState();
}

// ignore: camel_case_types
class _splash_screenState extends State<splash_screen> {
  late RiveAnimationController _buttonAnimationController;

  bool isShowSignInDialog = false;
  late final BluetoothAdapterState? adapterState;
  late StreamSubscription<BluetoothAdapterState> adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = OneShotAnimation("active", autoplay: false);
    adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            RiveAnimation.asset("assets/rive_assets/shapes.riv"),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: SizedBox(),
              ),
            ),
            Center(
              child: Container(
                  width: size.width * 0.8,
                  child:
                      Image.asset("assets/images/Algofet primary subtext.png")),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    "AlgoSAFE",
                    style: TextStyle(
                        fontSize: size.height * 0.05,
                        fontWeight: FontWeight.w400,
                        color: Colors.black),
                  ),
                ),
                SizedBox(
                  height: size.height * 0.01,
                ),
                AnimatedBtn(
                  btnAnimationController: _buttonAnimationController,
                  press: () async {
                    _buttonAnimationController.isActive = true;

                    Future.delayed(Duration(seconds: 1), () {
                      setState(() {
                        isShowSignInDialog = true;
                      });
                      showCustomDialog(
                        context,
                        onValue: (_) {},
                      );
                    });
                  },
                ),
                SizedBox(
                  height: size.height * 0.01,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
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
