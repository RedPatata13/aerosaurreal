import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class EntryGate extends StatefulWidget {
  const EntryGate({super.key});

  @override
  State<EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<EntryGate> {
  late StreamSubscription<User?> _authSubscription;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) async {
      if (!mounted) return;

      if (user != null) {
        await _checkLocationPermission();
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  Future<void> _checkLocationPermission() async {
    while (true) {
      final status = await Permission.locationWhenInUse.request();

      if (status.isGranted) {
        Navigator.pushReplacementNamed(context, '/app');
        break;
      } else if (status.isDenied) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'This app requires location permission to detect Wi-Fi. Please allow location access to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      } else if (status.isPermanentlyDenied) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location permission is permanently denied. You must enable it in app settings to use this app.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
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
