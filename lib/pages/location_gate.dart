import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
              'You must allow location access to use this app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      } else if (status.isPermanentlyDenied) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
              'Location permission is permanently denied. Open app settings to enable it.',
            ),
            actions: [
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
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
