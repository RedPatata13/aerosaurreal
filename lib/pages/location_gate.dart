import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../components/app_dialogs.dart';

class LocationGate extends StatefulWidget {
  final Widget child;
  const LocationGate({super.key, required this.child});

  @override
  State<LocationGate> createState() => _LocationGateState();
}

class _LocationGateState extends State<LocationGate> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    while (!_hasPermission) {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        setState(() {
          _hasPermission = true;
        });
      } else if (status.isDenied) {
        await showAppMessageDialog(
          context,
          title: 'Location Required',
          message: 'You must allow location access to use this app.',
          actionLabel: 'Retry',
        );
      } else if (status.isPermanentlyDenied) {
        await showAppMessageDialog(
          context,
          title: 'Location Required',
          message:
              'Location permission is permanently denied. Open app settings to enable it.',
          actionLabel: 'Open Settings',
        );
        await openAppSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
