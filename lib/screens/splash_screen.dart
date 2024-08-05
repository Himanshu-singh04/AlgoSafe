import 'package:algo_safe/main.dart';
import 'package:algo_safe/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// ignore: camel_case_types
class splash_screen extends StatefulWidget {
  const splash_screen({super.key});

  @override
  State<splash_screen> createState() => _splash_screenState();
}

// ignore: camel_case_types
class _splash_screenState extends State<splash_screen> {

  @override
  void initState() {
    super.initState();
    navigate_to_home();
  }

  // routes the app to the home page ie. the scan screen  
  navigate_to_home() async {
    // delayed function with 4 sec delay
    await Future.delayed(const Duration(milliseconds: 4000), () {});
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacement(create_route());
  }

  // actual splash screen page activities
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Material(
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
                  child: Column(
                    children: [
                      SizedBox(
                        height: size.height * 0.1,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Image.asset(
                            "assets/images/Algofet primary subtext.png",
                            scale: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        "Experience the Fully Automated Drone operations",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w400),
                      ),
                      Spacer(),
                      SizedBox(
                          height: size.height * 0.15,
                          width: size.width * 0.35,
                          child: Lottie.asset("assets/gifs/drone_flying.json")),
                    ],
                  )),
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
              child: Center(
                child: Row(
                  children: [
                    SizedBox(
                      width: size.width * 0.1,
                    ),
                    Text(
                      "AlgoSAFE",
                      style: TextStyle(fontSize: size.height * 0.04, color: Colors.white),
                    ),
                    Spacer(),
                    Lottie.asset("assets/gifs/loading.json"),
                  ],
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }
}

// automatically routes the page to the next screen with a sliding animation 
Route create_route() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const home_page(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      // sliding animation for page change
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
