import 'package:algo_safe/screens/login_checker_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class verify extends StatefulWidget {
  const verify({super.key});

  @override
  State<verify> createState() => _verifyState();
}

class _verifyState extends State<verify> {

  @override
  void initState() {
    sendverification();
    super.initState();
  }

  sendverification() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification().then((value) => {
      Get.snackbar("Link sent", "A link has been send to your email", margin: EdgeInsets.all(30), snackPosition: SnackPosition.BOTTOM)
    });
  }

  reload () async {
    await FirebaseAuth.instance.currentUser!.reload().then((value) => {
      Get.offAll(wrapper())
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("verify"),
      ),
      body: Padding(padding: EdgeInsets.all(8)
      ,child: Center(
        child: Text("Email link sent"),
      ),),
      floatingActionButton: FloatingActionButton(onPressed: (() => reload()),child: Icon(Icons.back_hand),),
    );
  }
}