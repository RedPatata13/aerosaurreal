import 'package:flutter/material.dart';

import '../components/app_dialogs.dart';
import '../services/location/location_access_service.dart';

class LocationGate extends StatefulWidget {
  final Widget child;
  const LocationGate({super.key, required this.child});

  @override
  State<LocationGate> createState() => _LocationGateState();
}

class _LocationGateState extends State<LocationGate>
    with WidgetsBindingObserver {
  bool _hasAccess = false;
  bool _checkingAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureLocationAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (mounted) {
      setState(() {
        _hasAccess = false;
      });
    }
    _ensureLocationAccess();
  }

  Future<void> _ensureLocationAccess() async {
    if (_checkingAccess) {
      return;
    }

    _checkingAccess = true;

    try {
      while (mounted && !_hasAccess) {
        final issue = await LocationAccessService.getIssue(
          requestPermission: true,
        );
        if (!mounted) {
          return;
        }

        if (issue == LocationAccessIssue.none) {
          setState(() {
            _hasAccess = true;
          });
          return;
        }

        if (issue == LocationAccessIssue.permissionDenied) {
          await showAppMessageDialog(
            context,
            title: 'Location Required',
            message:
                'Turn on location permission so the app can detect Wi-Fi, scan devices, and show connectivity features correctly.',
            actionLabel: 'Retry',
          );
          continue;
        }

        final shouldOpenSettings = await showAppConfirmationDialog(
          context,
          title: issue == LocationAccessIssue.serviceDisabled
              ? 'Turn On Location'
              : 'Location Required',
          message: issue == LocationAccessIssue.serviceDisabled
              ? 'Location services are turned off. Enable your phone location so the app can use Wi-Fi and device setup features properly.'
              : 'Location permission is turned off for this app. Open settings to enable it.',
          cancelLabel: 'Close',
          confirmLabel: issue == LocationAccessIssue.serviceDisabled
              ? 'Open Location'
              : 'Open Settings',
        );

        if (shouldOpenSettings) {
          await LocationAccessService.openResolution(issue);
        }
      }
    } finally {
      _checkingAccess = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
