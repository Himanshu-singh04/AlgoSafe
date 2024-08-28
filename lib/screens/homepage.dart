import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  final user = FirebaseAuth.instance.currentUser;

  signout() async {
    // await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home page"),
      ),
      body: Center(
        child:Text("${user!.email}")
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => signout(), child: Text("end"),),
    );
  }
}