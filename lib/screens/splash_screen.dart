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
  // double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _navigatetoHome();
    // _simulateProgress();
  }

  // void _simulateProgress() {
  //   Future.delayed(Duration(milliseconds: 70), () {
  //     setState(() {
  //       progress += 0.02;
  //       if (progress < 1.0) {
  //         _simulateProgress();
  //       }
  //     });
  //   });
  // }

  _navigatetoHome() async {
    await Future.delayed(const Duration(milliseconds: 4000), () {});
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacement(_createRoute());
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomRight,
                    colors: [CustomColors.gold, CustomColors.mainColor_1])),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Center(
                      child: Image.asset(
                          "assets/images/Algofet primary subtext.png",
                          height: size.height * 0.6,
                          width: size.width * 0.8)),
                  SizedBox(
                      height: size.height * 0.25,
                      width: size.width * 0.5,
                      child: Lottie.asset("assets/gifs/drone_flying.json")),
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(size.height * 0.01),
                  //       color: CustomColors.mainColor_1,
                  //     ),
                  //     width: size.width * 0.9,
                  //     height: size.height * 0.01,
                  //     child: LinearProgressIndicator(
                  //       value: progress,
                  //     ),
                  //   ),
                  // ),
                  Center(
                      child: Text(
                    "AlgoSAFE",
                    style: TextStyle(fontSize: size.height * 0.05),
                  )),
                ],
              ),
            ),
          )),
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
