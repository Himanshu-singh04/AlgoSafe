import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class loginpage extends StatefulWidget {
  const loginpage({super.key});

  @override
  State<loginpage> createState() => _loginpageState();
}

class _loginpageState extends State<loginpage> {

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  signin () async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text, password: password.text);
  }
  @override

  Widget build(BuildContext context) {
    return Scaffold(
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
            ElevatedButton(onPressed: () => signin(), child: Text("login"))
          ],
        ),
      ),
    );
  }
}