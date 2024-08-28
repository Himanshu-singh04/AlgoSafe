import 'package:algo_safe/screens/forgot.dart';
import 'package:algo_safe/screens/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class loginpage extends StatefulWidget {
  const loginpage({super.key});

  @override
  State<loginpage> createState() => _loginpageState();
}

class _loginpageState extends State<loginpage> {

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isloading = false;

  signin () async {
    setState(() {
      isloading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text, password: password.text);
    } on FirebaseAuthException catch(e){
      Get.snackbar("error msg", e.code);
    } catch(e){
      Get.snackbar("error msg", e.toString());
    }
    setState(() {
      isloading = false;
    });
  }

  googlesignin() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    final credentials = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken
    );

    await FirebaseAuth.instance.signInWithCredential(credentials);
    
  }

  @override

  Widget build(BuildContext context) {
    return isloading?Center(child: CircularProgressIndicator(),) :Scaffold(
      appBar: AppBar(title: Text("login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: InputDecoration(hintText: "Email"),
            ),
            TextField(
              controller: password,
              decoration: InputDecoration(hintText: "password"),
            ),
            ElevatedButton(onPressed: () => signin(), child: Text("login")),
            ElevatedButton(onPressed: () => Get.to(signup()), child: Text("register now")),
            ElevatedButton(onPressed: () => Get.to(forgot()), child: Text("forgot password")),
            ElevatedButton(onPressed: () => googlesignin(), child: Text("google login"))
          ],
        ),
      ),
    );
  }
}