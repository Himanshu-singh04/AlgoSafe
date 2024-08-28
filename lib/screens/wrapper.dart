import 'package:algo_safe/main.dart';
import 'package:algo_safe/screens/homepage.dart';
import 'package:algo_safe/screens/loginpage.dart';
import 'package:algo_safe/screens/verify.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class wrapper extends StatefulWidget {
  const wrapper({super.key});

  @override
  State<wrapper> createState() => _wrapperState();
}

class _wrapperState extends State<wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), builder: (context, snapshot){
        if (snapshot.hasData){
          if(snapshot.data!.emailVerified){
            return HomePage();
          }
          else{
            return verify();
          }
        }else{
          return loginpage();
        }
      }),

    );
  }
}