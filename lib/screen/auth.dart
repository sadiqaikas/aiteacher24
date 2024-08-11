import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:smathmathai/service/user.dart';

class UserAuth extends StatelessWidget {
  const UserAuth({super.key});

  @override
  Widget build(BuildContext context) {
    AuthService authService = AuthService();
    return Scaffold(
        body: Center(
      child: Container(
        width: 200,
        height: 50,
        child: SignInButton(
          Buttons.google,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          text: "Sign up with Google",
          onPressed: () {
            authService.signInWithGoogle().then((UserCredential user) {
              if (user.user != null) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            });
          },
        ),
      ),
    ));
  }
}
