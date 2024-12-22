import 'package:algo_safe/screens/email_login_screen.dart';
import 'package:algo_safe/screens/scan_drawer_screen.dart';
import 'package:algo_safe/screens/email_verify_screen.dart';
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
            return scan_drawer();
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