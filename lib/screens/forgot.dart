import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text("forgot password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: InputDecoration(hintText: "Email"),
            ),
            ElevatedButton(onPressed: () => reset(), child: Text("sign up"))
          ],
        ),
      ),
    );
  }
}