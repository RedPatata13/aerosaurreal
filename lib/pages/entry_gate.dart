import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; 

class EntryGate extends StatefulWidget {
  const EntryGate({super.key});

  @override
  State<EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<EntryGate> {
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;

      if (user != null) {
        // If logged in
        Navigator.pushReplacementNamed(context, '/app');
      } else {
        // If not logged in
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }
  
  // cancel subscription in dispose
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}