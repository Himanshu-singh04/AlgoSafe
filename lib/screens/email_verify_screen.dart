import 'package:algo_safe/screens/login_checker_screen.dart';
import 'package:algo_safe/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

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
    final Size size = MediaQuery.of(context).size;

    return Material(
      child: SingleChildScrollView(
        child: Container(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
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
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Container(height: size.height * 0.3,child: Lottie.asset("assets/gifs/sign_up_anime.json"))
                          ),
                        ),
                        Text(
                          "Login as User and experience the controls",
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w400),
                        ),
                        // Padding(
                        //   padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        //   child: Container(
                        //     child: TextField(
                        //       controller: email,
                        //       decoration: InputDecoration(hintText: "Email"),
                        //     ),
                        //   ),
                        // ),
                        // Padding(
                        //   padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                        //   child: TextField(
                        //     controller: password,
                        //     decoration: InputDecoration(hintText: "Password"),
                        //   ),
                        // ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                      "Check your email for verification link",
                                      style: TextStyle(
                                          color: Colors.black, fontWeight: FontWeight.w400),
                                    ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
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
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => reload(),
                        child: Container(
                          height: size.height * 0.05,
                          width: size.width * 0.8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            color: CustomColors.mainColor_3
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(CupertinoIcons.return_icon,color: Colors.white,),],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
            ],
          ),
        ),
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text("verify"),
    //   ),
    //   body: Padding(padding: EdgeInsets.all(8)
    //   ,child: Center(
    //     child: Text("Email link sent"),
    //   ),),
    //   floatingActionButton: FloatingActionButton(onPressed: (() => reload()),child: Icon(Icons.back_hand),),
    // );
  }
}