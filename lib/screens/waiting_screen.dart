// import 'package:algosafe/screens/display_page.dart';
import 'package:flutter/material.dart';

class waiting_screen extends StatefulWidget {
  const waiting_screen({super.key});

  @override
  State<waiting_screen> createState() => _waiting_screenState();
}

class _waiting_screenState extends State<waiting_screen> {

  @override
  void initState() {
    super.initState();
    _navigatetoNext();
  }

  _navigatetoNext() async {
    // await Future.delayed(Duration(milliseconds: 1500), (){});
    //Navigator.push(context, MaterialPageRoute(builder: (context) => display_page()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("waiting page"),
      ),
    );
  }
}