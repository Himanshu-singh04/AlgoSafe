import 'package:algo_safe/main.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

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
    _navigatetoHome();
  }

  _navigatetoHome() async {
    await Future.delayed(const Duration(milliseconds: 4000), (){});
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage(theme: ThemeData.light(),)));
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
            gradient: LinearGradient(begin: Alignment.topRight,end: Alignment.bottomRight,colors: [Color.fromRGBO(255, 255, 255, 1),Colors.grey])
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              Center(child: Image.asset("assets/images/Algofet primary subtext.png",height: size.height*0.6,width: size.width*0.8)),
              Center(child: AnimatedTextKit(animatedTexts: [TypewriterAnimatedText("AlgoSAFE v1.0",speed: const Duration(milliseconds: 250),textStyle: TextStyle(fontSize: size.width*0.1))],
                  totalRepeatCount: 7,displayFullTextOnTap: true,
              stopPauseOnTap: true,)),
              const CircularProgressIndicator(
                color: Colors.black,
              )
            ],),
          ),
        )
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






