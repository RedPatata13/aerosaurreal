import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../routes/routes.dart';
import '../services/api/api_client.dart';
import '../services/navigation/startup_route_resolver.dart';

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
        final route = await StartupRouteResolver(
          context.read<ApiClient>(),
        ).resolve(user.uid);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, route);
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
