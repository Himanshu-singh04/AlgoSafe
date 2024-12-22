import 'package:algo_safe/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class forgot extends StatefulWidget {
  const forgot({super.key});

  @override
  State<forgot> createState() => _forgotState();
}

class _forgotState extends State<forgot> {
  TextEditingController email = TextEditingController();
  reset() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
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
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(70))),
                    child: Column(
                      children: [
                        SizedBox(
                          height: size.height * 0.1,
                        ),
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                              child: Container(
                                  height: size.height * 0.3,
                                  child: Lottie.asset(
                                      "assets/gifs/forgot_anime.json"))),
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
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        ElevatedButton(
                          onPressed: () => reset(),
                          child: Text(
                            "Reset Password",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: CustomColors.mainColor_1),
                        )
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
                ),
              )
            ],
          ),
        ),
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(title: Text("forgot password"),
    //   ),
    //   body: Padding(
    //     padding: const EdgeInsets.all(8.0),
    //     child: Column(
    //       children: [
    //         TextField(
    //           controller: email,
    //           decoration: InputDecoration(hintText: "Email"),
    //         ),
    //         ElevatedButton(onPressed: () => reset(), child: Text("sign up"))
    //       ],
    //     ),
    //   ),
    // );
  }
}
