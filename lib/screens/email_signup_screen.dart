import 'package:algo_safe/screens/email_login_screen.dart';
import 'package:algo_safe/screens/login_checker_screen.dart';
import 'package:algo_safe/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class signup extends StatefulWidget {
  const signup({super.key});

  @override
  State<signup> createState() => _signupState();
}

class _signupState extends State<signup> {

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  signup() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text, password: password.text);
    Get.offAll(wrapper());
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: Container(
                            child: TextField(
                              controller: email,
                              decoration: InputDecoration(hintText: "Email"),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                          child: TextField(
                            controller: password,
                            decoration: InputDecoration(hintText: "Password"),
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                      "Already have an account ?",
                                      style: TextStyle(
                                          color: Colors.black, fontWeight: FontWeight.w400),
                                    ),
                                    TextButton(onPressed: (() => Get.to(loginpage())), child: Text("Login")),
                              ],
                            ),
                            ElevatedButton(onPressed: () => signup(), child: Text("Login",style: TextStyle(color: Colors.white),),style: ElevatedButton.styleFrom(backgroundColor: CustomColors.mainColor_1),),
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
                        // onTap: () => googlesignin(),
                        child: Container(
                          height: size.height * 0.05,
                          width: size.width * 0.8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            color: CustomColors.mainColor_3
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(CupertinoIcons.mail,color: Colors.white,),
                            SizedBox(width: size.width * 0.05,),
                            Text("Sign In with Google account",style: TextStyle(color: Colors.white),)],
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
    //   appBar: AppBar(title: Text("sign in"),
    //   ),
    //   body: Padding(
    //     padding: const EdgeInsets.all(8.0),
    //     child: Column(
    //       children: [
    //         TextField(
    //           controller: email,
    //           decoration: InputDecoration(hintText: "Email"),
    //         ),
    //         TextField(
    //           controller: password,
    //           decoration: InputDecoration(hintText: "password"),
    //         ),
    //         ElevatedButton(onPressed: () => signup(), child: Text("reset password"))
    //       ],
    //     ),
    //   ),
    // );
  }
}