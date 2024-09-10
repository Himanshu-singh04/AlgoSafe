import 'package:algo_safe/screens/forgot.dart';
import 'package:algo_safe/screens/email_signup_screen.dart';
import 'package:algo_safe/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';

class loginpage extends StatefulWidget {
  const loginpage({super.key});

  @override
  State<loginpage> createState() => _loginpageState();
}

class _loginpageState extends State<loginpage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isloading = false;

  signin() async {
    setState(() {
      isloading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text, password: password.text);
    } on FirebaseAuthException catch (e) {
      Get.snackbar("error msg", e.code);
    } catch (e) {
      Get.snackbar("error msg", e.toString());
    }
    setState(() {
      isloading = false;
    });
  }

  googlesignin() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credentials = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);

    await FirebaseAuth.instance.signInWithCredential(credentials);
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
                            child: Container(height: size.height * 0.3,child: Lottie.asset("assets/gifs/login_anime.json"))
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
                            decoration: InputDecoration(hintText: "password"),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't remember your password ?",
                              style: TextStyle(
                                  color: Colors.black, fontWeight: FontWeight.w400),
                            ),
                            TextButton(onPressed: (() => Get.to(forgot())), child: Text("Reset password")),
                          ],
                        ),
                        Text("OR"),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                      "Don't have an account ?",
                                      style: TextStyle(
                                          color: Colors.black, fontWeight: FontWeight.w400),
                                    ),
                                    TextButton(onPressed: (() => Get.to(signup())), child: Text("Register Now")),
                              ],
                            ),
                            ElevatedButton(onPressed: () => signin(), child: Text("Login",style: TextStyle(color: Colors.white),),style: ElevatedButton.styleFrom(backgroundColor: CustomColors.mainColor_1),),
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
                        onTap: () => googlesignin(),
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
    // return isloading?Center(child: CircularProgressIndicator(),) :Scaffold(
    //   appBar: AppBar(title: Text("login"),
    //   ),
    //   body: Padding(
    //     padding: const EdgeInsets.all(8.0),
    //     child: Column(
    //       children: [
    // TextField(
    //   controller: email,
    //   decoration: InputDecoration(hintText: "Email"),
    // ),
    // TextField(
    //   controller: password,
    //   decoration: InputDecoration(hintText: "password"),
    // ),
    //         ElevatedButton(onPressed: () => signin(), child: Text("login")),
    //         ElevatedButton(onPressed: () => Get.to(signup()), child: Text("register now")),
    //         ElevatedButton(onPressed: () => Get.to(forgot()), child: Text("forgot password")),
    //         ElevatedButton(onPressed: () => googlesignin(), child: Text("google login"))
    //       ],
    //     ),
    //   ),
    // );
  }
}
