import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../routes/routes.dart';

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

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) async {
      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.premium);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
