// import 'package:flutter_application_1/main.dart'
import "package:flutter/material.dart";

class GoogleSignInButton extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Image.asset(
          'images/google_logo.png',
          height: 20,
        ),
        onPressed: () {
          // _handleSignIn();
        },
        label: const Text('Google'),
      ),
    );
  }
}