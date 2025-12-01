import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'firebase_options.dart';
import 'pages/entry_gate.dart';
import 'pages/login.dart';
import 'pages/signin.dart';
import 'pages/home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  await dotenv.load(fileName: '.env');

  runApp(MaterialApp(
    title: 'Aerosaur',
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes : {
      '/' : (context) => const EntryGate(),
      '/signup' : (context) => const SignUpPage(),
      '/login' : (context) => const LoginPage(),
      '/app' : (context) => const HomePage()
    },
  ));
}